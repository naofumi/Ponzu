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
  #     respond_to :html, :js # Tell #respond_with what formats to respond to
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
  #    contains any errors. If so, then render the action appropirate for the
  #    current REST verb (if POST -> :new, PUT -> :edit). If you want to use
  #    a different action, then you can provide :action => [desired_action] in
  #    #respond_with. Rendering is handled by Responder#render, which delegates
  #    to Controller#render by default.
  # 3. If there are no errors, then ActiveController::Responder redirects
  #    to url_for(resource) (i.e. url_for(@meet_up)). You can change the location of
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
  #    exist, then it will fallback to the default (which is also the default for the PC view).
  # 2. By overriding Responder#render with Kamishibai::Responder#render the
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
  module ResponderMixin
    def self.included(base)
      base.responder = Kamishibai::Responder
    end

    def default_render(*args)
      device_selective_render(*args)
    end

  end
  
  class Responder < ActionController::Responder
    def render(*args)
      @controller.instance_eval do
        device_selective_render(*args)
      end
    end
    def redirect_to(*args)
      @controller.instance_eval do
        device_selective_redirect(*args)
        # if request.xhr?
        #   js_redirect ksp(args[0])
        # else
        #   redirect_to *args
        # end
      end
    end

  end
end