module Kamishibai
  # This is included into ApplicationController and provides methods
  # to invalidate Kamishibai localStorage caches.
  #
  # It is basically a configuration file that specifies which
  # cache-fragments should be invalidated when a specific object
  # is updated.
  #
  # TODO: We need to find a way to set this in a separate configuration
  # file.
  module Cache
    # seconds. 0 means don't cache.
    DEFAULT_EXPIRY = 0 

    def Cache.included(mod)
      mod.helper_method :invalidated_paths
    end

    private

    # The array specifies paths which should be invalidated and is
    # sent from the server in response to a form submittal. Use this
    # in cases where the cache keys to invalidate cannot be determined prior
    # to sending the form. For example, when creating a new MeetUp, we specify the
    # date. This means that one of the pages that lists MeetUps by date must
    # be invalidated, but we cannot be sure which one. We can only know this 
    # after the form has been processed on the server.
    #
    # The paths that are set with ks_cache_invalidate will be sent in a
    # custom HTTP header (this information should not be cached and hence we don't want
    # to send it in the body).
    def ks_cache_invalidate(array)
      response.headers['X-Invalidate-Cache-Paths'] = array.to_json
    end

    # These are the paths that are invalidated when the form in submitted on the client.
    # These are set on the form DOM element itself.
    def invalidated_paths(object) # :doc:
      paths = if object.instance_of? User
        result = [user_path(object), settings_user_path(object)]
        result.push(author_path(object.author.id)) if object.author
        result
      elsif object.kind_of? Like
        base_string = "/presentations/#{object.presentation.id}"
        [
          "#{base_string}/social_box",
          "like_highlights",
          "list_highlights",
          "likes/(.+/)?my"
        ]
      elsif object.instance_of? Comment
        base_string = "/presentations/#{object.presentation.id}"
        [
          "#{base_string}/comments"
        ]
      elsif object.instance_of? Participation
        meet_up = object.meet_up
        [ meet_up_path(meet_up),
          meet_ups_path(:date => meet_up.starts_at.strftime('%Y-%m-%d')),
          meet_ups_ajax_dashboard_index_path,
          my_meet_ups_dashboard_index_path ]
      elsif object.instance_of? MeetUp
        crud_paths(object) +
          [meet_ups_ajax_dashboard_index_path]
      elsif object.instance_of? PrivateMessage
        [ "private_message" ]
      else
        raise ('invalidation path not specified')
      end
      paths.join(' ')
    end

    def crud_paths(object) # :doc:
      paths = [ 
        url_for(:controller => object.class.to_s.underscore.pluralize, :action => 'index', :only_path => true),
        url_for(:controller => object.class.to_s.underscore.pluralize, :action => 'new', :only_path => true)
      ]
      if !object.new_record?
        paths += [
          url_for(:controller => object.class.to_s.underscore.pluralize, :action => 'edit', :id => object, :only_path => true),
          url_for(:controller => object.class.to_s.underscore.pluralize, :action => 'show', :id => object, :only_path => true)
        ]
      end
      paths
    end

  end
end