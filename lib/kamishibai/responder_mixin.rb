module Kamishibai
  # Kamishibai::Responder makes Ponzu/Kamishibai rendering easy.
  #
  # Typically, writing the rendering portion of a Ponzu controller action
  # is extremely tedious. An example is as follows;
  #
  #     def show
  #       date_string = params[:id] || '2011-12-14'
  #    
  #       @show_date = Time.parse(date_string)
  #       @sessions = Session::TimeTableable.all_in_day(@show_date).includes(:room).all
  #       
  #       respond_to do |format|
  #         if request.xhr?
  #           if smartphone?
  #             format.html{ render "#{__method__}.s", :layout => false }
  #           else
  #             format.html{ render :layout => false }
  #           end
  #         else
  #           if smartphone?
  #             format.html{ render "#{__method__}.s" }
  #           elsif galapagos?
  #             format.html{ render_sjis "#{__method__}.g" }
  #           else
  #             format.html{ render }
  #           end
  #         end
  #       end
  #     end
  #
  # In Ponzu, we have to select the template file based on user agent. This 
  # makes the #respond_to block very complicated.
  #
  # Rails by default provides a #respond_with method which eliminates the
  # need to write a respond_to block for the majority of CRUD. However, 
  # it is insufficient for device dependent rendering of views as with
  # Ponzu. Additionally, the #redirect_to (based on response headers) simply does
  # not work with Ajax. Therefore, we have subclassed ActionController::Responder
  # to support Ponzu and Ajax, and to respond to multiple devices accordingly.
  #
  # Usage of Kamishibai::Responder should be almost identical to
  # ActionController::Responder.
  #
  # == Usage
  #
  #   class MeetUpsController < ApplicationController
  #     respond_to :html, :js, :json # Tell #respond_with what formats to respond to
  #     include Kamishibai::ResponderMixin
  #
  #     def index
  #       @meet_ups = MeetUp.where([some conditions]).paginate(:page => parmas[:page])
  #   
  #       respond_with @meet_ups # The #respond_to block is now a simple method call.
  #     end
  #
  # == How Kamishibai::ResponderMixin responds
  #
  # First, we need to understand how ActiveController::Responder works.
  # For html responses, ActiveController::Responder executes the following flow;
  #
  # 1. Attempt a Controller#default_render. Controller#default_render chooses the
  #    view template file matching the current action. You can override this
  #    if you have specified a block that responds to the html format in the
  #    #respond_with block.
  # 2. If Controller#default_render fails, then check if the resource (i.e. @meet_ups)
  #    contains any errors. If so, then render the action appropriate for the
  #    current REST verb (if POST -> :new, PUT -> :edit). If you want to use
  #    a different action, then you can provide :action => [desired_action] in
  #    #respond_with. Rendering is handled by Responder#render, which delegates
  #    to Controller#render by default.
  # 3. #default_render failed but if there are no errors, then ActiveController::Responder redirects
  #    to url_for(resource) (i.e. url_for(@meet_up)). This would be the case
  #    for an :update or :create. You can change the location of
  #    the redirect with :location => [desired_location]. The redirect is handled
  #    by Responder#redirect_to, which delegates to the Controller#redirect_to.
  #
  # By including Kamishibai::ResponderMixin, we overwrite Controller#default_render
  # and set the Controller.responder = Kamishibai::Responder.
  #
  # Kamishibai::ResponderMixin changes the ActiveController::Responder as follows.
  #
  # 1. By overriding Controller#default_render with Kamishibai::Controller#device_selective_render,
  #    all renders that attempt to use the view template named after the current action
  #    will first look for a device-selective template. If such a template does not
  #    exist, then it will fallback to the default (which is the PC view).
  # 2. By overriding Responder#render with Kamishibai::Responder#render so that
  #    Kamishibai::Controller#device_selective_render is eventually called, the
  #    renders that are deduced from the REST verbs and the resource error status
  #    (namely the :create and :update renders) will also search first for a 
  #    device-selective template, falling back to the default if not found.
  # 3. By overrideing Responder#redirect_to with Kamishibai::Responder.redirect_to
  #    (which delegates to Kamishibai::Controller#js_redirect if the request is XHR),
  #    we can handle redirects by telling the browser to change the fragment hash
  #    and force a hashChange event, which will then send a new Ajax request.
  #
  # == Summing up
  #
  # ActiveController::Responder implements the POST-then-redirect pattern. 
  # By assuming the REST convention, a simple <tt>#redirect_with @meet_up</tt> 
  # command can automatically determine which view templates to use and when
  # to redirect. This drastically simplifies the code.
  # 
  # By including the Kamishibai::ResponderMixin, you can do the same with Kamishibai
  # and device selective view-templates. This also uses the POST-then-redirect pattern.
  # 
  # == Code examples that we want to realize
  #
  # # POST and redirect as applied to Kamishibai
  # # Flash messages should show up on the first Ajax response
  # # before redirect.
  # def create
  #   @meet_up = MeetUp.new(params[:meet_up])
  #   set_flash @meet_up.save, 
  #             :success => "Successfully created Yoruzemi"
  #             :fail => "Failed to create Yoruzemi"
  # 
  #   respond_with @meet_up
  # end
  #
  # # If we want to show the edit action on success
  # # to make it more like a native app.
  # # Since Kamishibai generally won't reload and scroll to top,
  # # everything should look unchanged.
  # # It is a POST and redirect to edit pattern.
  # # Flash messages should show up on the first Ajax response
  # # before redirect.
  # def create
  #   @meet_up = MeetUp.new(params[:meet_up])
  #   set_flash @meet_up.save, 
  #             :success => "Successfully created Yoruzemi"
  #             :fail => "Failed to create Yoruzemi"
  # 
  #   respond_with :location => edit_meet_up_path(@meet_up), @meet_up
  # end
  #
  # # If we want to show the edit action on success
  # # to make it more like a native app.
  # # This is similar to the above example where we redirected
  # # to the edit_meet_up_path (POST and redirect pattern).
  # # However, since Kamishibai sends the POST request via
  # # Ajax, we don't have to worry about double-posting
  # # by reloads, etc. and hence we don't have to adhere
  # # to the POST and redirect pattern.
  # # This is a POST and render pattern that would
  # # not be recommended on normal HTML, but works OK
  # # with an Ajax POST.
  # # Flash messages are processed in Kamishibai::Flash
  # # so that they will appear in the rendered page
  # # instead of waiting for the redirect (which won't
  # # happen in this case).
  # #
  # # Note that if the request is non-ajax, :success_action
  # # will have no effect and the POST and render pattern
  # # will not be applied. Instead, a POST and redirect pattern
  # # will be used, with the destination determined from the 
  # # @meet_up resource of the :location option, if specified.
  # def create
  #   @meet_up = MeetUp.new(params[:meet_up])
  #   set_flash @meet_up.save, 
  #             :success => "Successfully created Yoruzemi"
  #             :fail => "Failed to create Yoruzemi"
  # 
  #   respond_with :success_action => :edit, @meet_up
  # end
  #
  # def index
  #   @meet_ups = MeetUp.all
  # end
  #
  # def show
  #   @meet_up = MeetUp.find(params[:id])
  # end
  #
  # def search
  #   @meet_ups = MeetUp.where(:meet_up_name => params[:query])
  # end
  #
  # def destroy
  #   @meet_up = MeetUp.find(params[:id])
  #   if @meet_up.destroy
  #     flash[:notice] = "Successfully destroyed"
  #   else
  #     flash[:error] = "Failed to destroy"
  #   end
  #   respond_with @meet_up
  # end
  #
  # 
  # To see typical controller snippets, take a look at sessions_controller.rb 
  # 
  # 
  # 
  # 
  # 
  # 
  # = The following is likely to be outdated. We need to check.  
  # == [Not real] How to use the POST-then-replace pattern with Kamishibai::ResponderMixin
  #
  #     app/controllers/meet_up_controller.rb
  #     def create
  #       @meet_up = MeetUp.new(params[:meet_up])
  #       if @meet_up.save
  #         flash[:notice] = "Successfully created Yoruzemi"
  #         device_selective_render # render app/views/meet_ups/create.html.haml
  #       else
  #         flash[:error] = "Failed to create Yoruzemi"
  #         device_selective_render :new
  #       end
  #     end
  #     # app/views/meet_ups/create.html.haml
  #     = ks_element :id => "meet_up_details" do
  #       = render :partial => "meet_up_details"
  #
  # In the above example, the response was HTML. We rely on Kamishibai to intelligently
  # insert each Kamishibai element into the correct locations in the DOM.
  #
  # We can also respond with JavaScript (create.js.erb), and the Javascript will be
  # executed on the browser.
  #
  # == How to customized #respond_with behavior with a block (multi-device POST-then-replace)
  #
  # The previous POST-then-replace pattern doesn't really work when we have to
  # handle Ajax and non-Ajax requests in the same code. This is because in these
  # cases, the Ajax is POST-then-replace but the non-Ajax is POST-then-redirect.
  # In the above code, #device_selective_render can only handle rendering; it cannot
  # redirect.
  #
  # To handle these cases, we have to understand how to use the block option.
  #
  # We start with the following code. Here we are implementing a "like" button.
  # 
  # 
  #     respond_to do |format|
  #       if @like.save
  #         format.html { 
  #           flash[:notice] = "New like was created"
  #           if request.xhr?
  #             render :partial => 'like_button', :locals => {:presentation => @like.presentation}
  #           else
  #             redirect_to @like.presentation
  #           end
  #         }
  #       else
  #         format.html { 
  #           flash[:error] = "Failed to create new like"
  #           if request.xhr?
  #             render :partial => 'like_button', :locals => {:presentation => @like.presentation}
  #           else
  #             redirect_to @like.presentation
  #           end
  #         }
  #       end
  #     end
  #
  # For Ajax clients, we want to send a partial for both success and failure.
  # #respond_with redirects on success and renders a view (not a partial) on failure. 
  # Neither is what we want.
  #
  # For non-Ajax clients, we want to redirect to @like.presentation on success
  # and also redirect to the same on failure. #respond_with can redirect to
  # @like.presentation on success by setting the <tt>:location</tt> option,
  # but we can't redirect on failure.
  #
  # We ended up using the following code.
  #
  #     if @like.save
  #       flash[:notice] = "New like was created"
  #     else
  #       flash[:error] = "Failed to create new like"
  #     end
  #
  #     respond_with @like, :location => @like.presentation do |format|
  #       if request.xhr?
  #         format.html {render :partial => 'like_button', :locals => {:presentation => @like.presentation}}
  #       elsif !@like.errors.empty?
  #         format.html { redirect_to @like.presentation }
  #       end
  #     end
  #
  # The code in the block is always prioritized. If a MIME block that matches
  # the requested MIME is found inside the block, that is always executed.
  #
  # (the code does not do #device_selective_render because I don't need it yet
  # and our #device_selective_render doesn't yet handle partials.)
  #
  # The cases that we need to include in the block are the ones that
  # #respond_with cannot handle;
  #
  # 1. Sending a partial for XHR requests for both success and failure.
  # 2. Redirecting to @like.presentation for non-XHR requests.
  #
  # Conversely, we can handle successful non-Ajax requests within #respond_with
  # by setting <tt>:location => @like.presentation</tt> as an argument. Hence
  # this code does not have to be included in the block (although it might
  # actually make the code easier to understand.)
  #
  # If we mistakenly write the following code it won't work on non-Ajax clients when
  # save succeeds (it will ignore the +:location+ that we set in the argument).
  #
  #     format.html {
  #       if request.xhr?
  #         render :partial => 'like_button', :locals => {:presentation => @like.presentation}
  #       elsif !@like.errors.empty?
  #         redirect_to @like.presentation
  #       end        
  #     }
  #
  # This is because the Responder will see the <tt>format.html</tt> and assume
  # that this should handle any +html+ MIME request. However in reality, we have only
  # provided non-Ajax code for the success case. Responder doesn't know this because
  # it hasn't actually run the code inside the MIME blocks yet.
  #
  #
  #
  # General thoughts
  #
  # They do not provide the flexibility of the original #render method, in that
  # they select a response mime before checking for the availability of a template.
  # In this sense, they make rendering a bit more brittle. You can't simply
  # provide the templates with the mimes that you want to respond to. You need
  # to configure inside the #respond_to block.
  #
  # With #respond_with, they address the boilerplate issue. A lot of the common
  # stuff is addressed with a simple command. However, the brittleness remains.
  # You cannot simply change the mime you want to respond with by changing the
  # template mime.
  #
  # I want the boilerplate issue to be resolved, and to also use a device
  # specific template if available. I want to specify everything simply by
  # providing template files. If providing a template file is too tedious,
  # I want to be able to provide the rendering routine directly, but still
  # want to be able to use template files 
  #
  # Inside MimeResponds#retrieve_collector_from_mimes, they decide on a
  # format they want to use for the response. This is great if that response
  # is actually implemented, but if we remove the brittleness, then sometimes
  # it won't. We won't know until we've looked at the template files.
  #
  # If the response was written in the block with a format.html{} like notation,
  # then it's OK to complain if the template for html was not provided.
  #
  # Otherwise, we should remain flexible and allow various responses based
  # on the availability of the templates.
  #
  # 
  # Thoughts on partials
  #
  # #respond_with does not originally support partials nor do we want to either.
  # Partials are often used in Ajax responses because it allows us to transition
  # easily from a non-Ajax UI to an Ajax UI. That's really the only reason we
  # need partials.
  #
  # This is useful if you want to draw an element first as a part of a traditional
  # HTML response, and also update it later with Ajax. Very common approach.
  #
  # We'll look more carefully into use cases and then think about this again.
  #
  # 
  module ResponderMixin
    def self.included(base)
      base.responder = Kamishibai::Responder
    end

    def default_render(*args)
      # In #retrieve_collector_from_mimes, we set self.content_type to the
      # type as determined before checking the template files for availability.
      #
      # This is OK when a response_block is provided because that explicity
      # specifies the response mime type. However, it is bad when the actual
      # template files determine the mime type.
      #
      # Therefore, if the template file for that content_type is missing and
      # a different template file with a difference mime_type is used,
      # the content_type will no longer match the actual content.
      #
      # To prevent this, we set content_type to nil when we use the template
      # files without a response_block.
      #
      # We do the same thing on the Responder#render method.
      self.content_type = nil
      device_selective_render(*args)
    end

    def respond_with(*resources, &block)
      raise "In order to use respond_with, first you need to declare the formats your " <<
            "controller responds to in the class level" if self.class.mimes_for_respond_to.empty?

      # In the original #respond_with code (#retrieve_collector_from_mimes), the formats
      # that can be used to respond are determined from the original controller.formats
      # and the respond_with block, without checking whether the template files for each
      # format exists or not. It then sets controller.formats to only that format.
      #
      # For example, if we remove the template file for :html but controller.formats includes
      # :html, we get an error, even if we have a template file for :json.
      #
      # This is not how #render handles mimes. #render checks for the existence of the template
      # file for :html, but if it can't find one, then it looks for the next candidate in 
      # controller.formats. #render_with calls #render, but it can't do its magic because
      # controller.formats has been reduced to only the first format candidate.
      #
      # The reason for doing this is probably because in the #to_format method, they use
      # the default_render to render a template and if a template file is not available, they
      # automatically want to do a 
      #   render :xml => @user
      # kind of thing, instead of trying out the next format in controller.formats.
      #
      # We want the original #render behaviour inside #respond_with, so that #respond_with will
      # look at the available files and respond accordingly. We will never simply render a whole
      # resource into xml or json without customizing the output with a template.
      #
      # To get the original #render behaviour, we simply add back the missing stuff from the
      # original controller.formats.
      original_formats = formats

      if collector = retrieve_collector_from_mimes(&block)
        options = resources.size == 1 ? {} : resources.extract_options!
        options[:default_response] = collector.response
        # If the default_response was not provided in the response block,
        # then we remove the brittleness of #respond_with and revert to the
        # flexibility of #render
        if !(options[:default_response])
          # uniq preserves order so the format from #retrieve_collector_from_mimes 
          # will take precedence
          self.formats = (formats + original_formats).uniq 
          lookup_context.rendered_format = nil
        end
        (options.delete(:responder) || self.class.responder).call(self, resources, options)
      end
    end

  end
  
  class Responder < ActionController::Responder
    # Original ActionController::Responder delegates
    # #render to controller#render. We want it to
    # run #device_selective_render
    def render(*args)
      @controller.instance_eval do
        # See comments on ResponderMixin#default_render
        # for why we reset the content_type.
        self.content_type = nil
        device_selective_render(*args)
      end
    end

    # Original ActionController::Responder delegates
    # #redirect_to to controller#redirect_to. We want it to
    # run #device_selective_redirect
    def redirect_to(*args)
      @controller.instance_eval do
        device_selective_redirect(*args)
      end
    end

    # In the default Responder, an error will render the default_action
    # and a success will redirect_to the navigation_location (which
    # can be set with the :location). 
    #
    # For AJAX requests, we often want to
    # render instead of redirect. For this, we use the :success_action
    # option. 
    #
    # Additionally, we often want to redirect back on success.
    # This is done with :success_action => :back
    def navigation_behavior(error)
      if get?
        raise error
      elsif has_errors? && default_action
        render :action => default_action
      else
        if options[:success_action] && @controller.request.xhr?
          if options[:success_action] == :back
            # Use #send because #js_redirect is private
            # controller.js_redirect :back
            controller.send :js_redirect, :back
          else
            render :action => options[:success_action]
          end
        else
          redirect_to navigation_location
        end
      end
    end

    protected :navigation_behavior
  end
end