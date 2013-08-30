# Provides the #ksp helper method that generates a Kamishibai style
# hash fragment from a URL.
module KamishibaiPathHelper
  private

  # Generate a hashed Kamishibai path for the resourceUrl if Kamishibai is active
  # The following formats are accepted.
  #
  # <tt>ksp('/hello/show')</tt>::
  # <tt>ksp(@user)</tt>::
  # <tt>ksp(@user, :bootloader_path => "http://example.com/section")</tt>::
  #   The +:bootloader_path+ option is added to the front of the
  #   fragment to create a full URL or path. The value may be
  #   a full URL or a simple path like +/section+. It is prepended without
  #   further processing.
  #
  #   This is useful when you want to move to another bootloader or you
  #   want to provide a full URL (_i.e._ when you are using ActionMailer).
  # <tt>ksp(:user_path, 123, :page => 2)</tt>::
  # <tt>ksp([:user_path, "some_id"], 123)  -> #!_/users/123__some_id</tt>::
  # <tt>ksp([@user, "some_id"], 123)  -> #!_/users/123__some_id</tt>::
  #
  # If 
  def ksp(*args) # :doc:
    result = ""
    resource_arg = args.shift
    # Support for :bootloader_path and :force_galapagos option
    if args.last.kind_of? Hash
      bootloader_path = args.last.delete(:bootloader_path)
      force_galapagos = args.last.delete(:force_galapagos)
      force_kamishibai = args.last.delete(:force_kamishibai)
      args.pop if args.last.size == 0 # Remove if empty Hash
    end
    if resource_arg.kind_of? Array
      # ksp([:user_path, "some_id"], 123)
      path_string = path_for_resource(resource_arg[0], *args)
      id_string = resource_arg[1]
    else
      # ksp(:user_path, 123)
      path_string = path_for_resource(resource_arg, *args)
    end

    # We cannot respond to the device_scope when we are using ActionMailer,
    # (respond_to?(:device_scope_by_user_agent) returns false)
    # simply because we aren't sending to a browser. In this case, we
    # send the hash fragment version (which will work with Desktop and 
    # smartphone but not galapagos).
    # We can force a galapagos url by providing a :force_galapagos => true
    # option in the last argument.
    if !force_galapagos && 
       (force_kamishibai || !respond_to?(:device_scope_by_user_agent) || !galapagos?)
      path_string.sub!(/^https?:\/\/[^\/]*/, '')
      path_string = "#!_" + path_string
    end

    if bootloader_path
      path_string = bootloader_path + path_string
    end

    return path_string + (id_string ? "__#{id_string}" : "")
  end

  def path_for_resource(resource_arg, *args)
    # raise args.inspect
    if resource_arg.kind_of? String
      # ksp('/hello/show')
      path_string = resource_arg
    elsif resource_arg.kind_of? Symbol
      # ksp(:user_path, 123, :page => 2)
      path_string = send(resource_arg, *args)
    elsif !resource_arg
      path_string = request.path.blank? ? "/" : request.path
    else
      # ksp(@user)
      path_string = url_for(resource_arg, *args)
    end      
  end
end