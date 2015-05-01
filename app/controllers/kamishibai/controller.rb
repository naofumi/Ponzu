# = About Kamishibai
#
# Kamishibai is a Javascript framework for creating Web sites that can
# store significant amounts of data in browser local storage, and be 
# used offline. The most distinguishing features are below.
#
# 1. Designed to create offline websites based on tens of megabytes of data.
# 2. Not a client-side MVC framework. Almost all HTML is generated server-side
#    making development simple and quick.
# 3. Essentially, Kamishibai is a fragment-cache that works on the browser.
#    To improve storage efficiency and cache management, Kamishibai manages
#    fragments of a single web page separately, requesting and caching them
#    in discrete HTTP requests. Each fragment can be expired independently.
# 4. Kamishibai includes an intelligent compositor to stitch the fragments
#    together. As an additional bonus, we can use the compositor to send
#    Ajax fragments. As a result, we can do without RJS or tedious event
#    handlers to insert Ajax fragements into the desired locations.
#
# Kamishibai makes offline websites with tons of data realistic. It's the
# first framework that aims towards this goal. Other frameworks, including
# client-side MVC frameworks, do not have the capabilities to store and serve thousands
# of web pages offline.
#
# The Kamishibai API mostly consists of a href hash-fragment syntax and +data-+
# attributes on DOM elements. However the syntax is not developer-friendly,
# mostly due to limitations of HTML itself. Therefore, to provide an easier-to-grasp
# API, we have turned to Rails helper methods.
#
# We will describe the Rails API in detail in the RDoc. The Kamishibai API
# itself will be documented in the Javascript and also in the Pages section of this Rdoc.
# The Rdoc version is likely to be a bit outdated, so revisit the source when possible.
module Kamishibai

  # Provides helper methods to use within Controllers and Views to assist
  # Kamishibai command generation. For more helpers, see the Kamishibai
  # related view helpers as well.
  #
  # == Multi-device support
  #
  # Kamishibai aims to support multiple devices with the least amount of 
  # application-specific code. Device-specific code should be hidden inside the
  # library, and the application developer should ideally be able to code to
  # a single device; Kamishibai will generate the device-specific responses.
  #
  # Specifically, this means that Kamishibai controllers should be capable of 
  # the following.
  #
  # 1. Automatically selecting a device-specific view-template.
  # 2. Responding to both Ajax and non-Ajax requests.
  # 3. Handling error display in response to both Ajax and non-Ajax requests.
  # 4. Managing redirects for both Ajax and non-Ajax requests.
  #
  # === Helper methods for multi-device support
  #
  # device_selective_render::
  #
  #   This first tries to render using the appropriate device-specific view-template.
  #   For smartphones, this would be "[action].s" and for galapagos phones it would
  #   be "[action].g". If view-templates with these names cannot be found, then 
  #   it renders the default "[action]" view-template. Furthermore, for galapagos
  #   view-templates, it encodes the response in Shift-JIS.
  #
  #   Furthermore, if the request is XHR, then it does not render the layout 
  #   (:layout => false).
  #
  #   If Kamishibai::ResponderMixin is included into the current controller, then
  #   +default_render+ will be overridden to delegate to +device_selective_render+.
  #   This means that implicit rendering will use device_selective_render. The 
  #   device_selective_render method is still a work in progress and cannot yet 
  #   handle the variety of arguments that the original #render method can. That
  #   is why we do not overrider the +#render+ method.
  #
  # js_redirect::
  #
  #   This manages Javascript redirects. Before we understand this, we have to understand
  #   how redirects work, with or without Javascript.
  #
  #   The +#redirect_to+ method that Rails provides writes the URL to the "Location" entry
  #   of the response header. It also sets the status code to 302.
  #
  #   If the original request was a regular HTTP request, after receiving the redirect response,
  #   the browser would change the document.href to the value in the "Location" header, 
  #   and send a request to that location. The final response body will be rendered in
  #   the browser window.
  #
  #   However, if the original request was an Ajax request, then after receiving the
  #   redirect response, the browser will send another request to the value in "Location"
  #   and use the final response as the body for the Ajax response. The AjaxSuccess
  #   code will process this response body as appropriate. The important thing is
  #   that document.href will not change, and hence it is very different from 
  #   a regular redirect in terms of user experience.
  #
  #   To generate the same behavior as a regular HTTP redirect, the browser has to 
  #   explicitly change document.href. This is what #js_redirect does.
  #
  #   +#js_redirect+ takes a string or any argument that can be passed to +#url_for+
  #   and sends the Javascript to the browser that will change document.href to
  #   the appropriate URL. Since +js_redirect+ sets the "Content-type" response
  #   header iteself, you can use it inside an HTML mime block in the following manner.
  #
  #     respond_to do |format|
  #       format.html {
  #         if reqeust.xhr?
  #           js_redirect @post
  #         else
  #           redirect_to @post
  #         end
  #       }
  #
  #   Additionally, +js_redirect+ will remove the "Location" header, if set,
  #   because we don't want to redirect the Ajax response itself.
  #
  #   Instead of sending Javascript to the browser, another approach is to 
  #   use Javascript to read the contents of the "Location" response header
  #   before Ajax is redirected, and to write Javascript to change the 
  #   browser location.href accordingly.
  #   
  #   In Kamishibai, we dismissed this idea because we didn't want to change
  #   regular browser behavior. It was also questionable whether all browsers would
  #   enable us to intercept the Ajax before it was redirected.
  #
  #   We don't currently have a +#device_selective_redirect_to+, but it is 
  #   something that we are considering.
  #
  # respond_with::
  #
  #   Selecting how to respond to each action, especially in response to validation
  #   errors, tends to get rather complicated. The complication becomes
  #   quite severe when we also have to consider multiple devices.
  #
  #   Rails provides ActionController::MimeResponds#responds_with which 
  #   simplifies response selection for RESTful interfaces. We subclassed
  #   ActionController::Responder to create Kamishibai::Responder, which
  #   includes multi-device support. Kamishibai::Responder is set by including
  #   Kamishibai::ResponderMixin in the current controller class.
  #
  #   Kamishibai::Responder automatically manages complicated responses
  #   and POST-and-redirect responses for multiple devices. Use it as
  #   you would normally use #respond_with for regular HTTP requests.
  #
  # == +csrf_token+, +csrf_param+ management
  #
  # Rails guards against cross-site scripting attacks by providing a random number
  # as the +csrf_token+. For each request (session?), the server generates a +csrf_token+
  # and sets an HTTP-only cookie with that value. Any forms generated by the Rails
  # form helpers also include this token as a hidden field. Furthermore, the +csrf_token+
  # is also set in the +header+ tag portion of the web page, so that rails.ujs libraries
  # can refer to it and send the value with any POST requests.
  # 
  # When the server recieves a non-GET request, it compares the +token+ value sent
  # as POST (or PUT, DELETE) params with the value in the HTTP-only cookie. It will
  # accept the request only if the values match.
  #
  # This is a problem in Kamishibai because +form+ DOMs and +header+ DOMs are likely to
  # be cached on the browser. Hence the +csrf_token+ values will likely be stale if
  # read from the browser cache.
  #
  # To fix this, we set the +csfr_token+ inside a special cookie on every request. The value
  # of this cookie will never be cached and will always be identical to the 
  # +csfr_token+ inside the HTTP-only cookie. This is because these cookies
  # are always updated in the same response. For every request that passes through
  # rails.rjs, we merge the +csfr-token+ value in the params. The server checks 
  # that the value is identical to that in the HTTP-only cookie and if OK, 
  # accepts the request.
  #
  # This is done through the #csrf_token_in_cookie method, which is set on every
  # request via a #before_filter. You should never have to do anything manually.
  #
  # == General CRUD design patterns
  #
  # Ruby-on-Rails' scaffolds demonstrate a best-practice design pattern. 
  # Specifically, they do a POST-and-redirect for the #create and #update
  # methods. Rails also provides a convinient #format_with method to
  # automate this based on convention-over-configuration.
  #
  # For AJAX websites however, a POST-and-replace pattern is common. Unfortunately,
  # Rails does not provide a nice scaffold nor does it provide any 
  # helper methods to assist this pattern. 
  #
  # One goal of Kamishibai is to extend the convention-over-configuration
  # concept to Ajax. Rails only helps with the non-Ajax design patterns.
  # We want to make Ajax design patterns as easy to work with.
  # We will look into the Kamishibai CRUD design patterns and compare them
  # to regular Rails, and common Ajax patterns. We will see if we can
  # build the best-practice design into a simple helper.
  #
  # Kamishibai attempts very hard to make Ajax as simple as regular
  # Rails. Hence the Kamishibai design pattern tries to mirror the
  # Rails pattern as closely as possible, with optional optimizations
  # for preformance when necessary. The common Ajax POST-and-replace pattern
  # is one of these performance optimizations.
  #
  # Neither Turbolinks nor PJAX concerns itself with CRUD.
  # They work on regular link and are not designed to handle forms. 
  # Forms are handled with regular page loads in these libraries.
  #
  # === POST-and-redirect design pattern.
  #
  # This pattern is described well in this page;
  # http://web.archive.org/web/20061029012755/http://adamv.com/dev/articles/getafterpost
  # http://web.archive.org/web/20061113164139/http://www.theserverside.com/tt/articles/article.tss%3Fl%3DRedirectAfterPost
  #
  # The issue stems from the fact that if the user hits reload
  # on a page that is a result of a POST, then the POST data will
  # resent to the server, causing double submit problems and 
  # also scaring the user with a dialog box warning.
  #
  # The guidelines are;
  #
  # 1. Never show pages in response to POST 
  # 2. Always load pages using GET
  # 3. Navigate from POST to GET using REDIRECT
  #
  # However if the POST request is sent via Ajax from a page that came
  # from a GET request, a browser reload will only trigger the GET
  # request for the page and it will not trigger the POST. Hence
  # with Ajax, we can avoid doing the REDIRECT which will improve
  # performance due to one less HTTP request/response cycle.
  # In short, with Ajax, the POST-and-replace pattern is feasible.
  # 
  # === POST-and-replace for forms integrated into #show views
  #
  # In this pattern, instead of having a dedicated URL for the #new and #edit
  # views, we insert the form inside the #show view. This is common for comments
  # on a blog post, where the form is already displayed when you view the post.
  # The desired behaviour after POST would normally be to simply add the 
  # new comment onto the list of comments.
  #
  # === POST-and-replace for continous editing in #edit views
  #
  # For example, if we were inside an Admin interface, we often want to
  # keep editing even after we submit the form.
  # In this case, the flow should be the following;
  #
  # 1. #new to create a new entry.
  # 2. Redirect to #edit on new entry success. Use #js_redirect for this.
  # 3. On update, re-render the #edit view. Simply use <tt>render :edit</tt>.
  #
  # If we didn't have a dedicated #edit view, but instead included a
  # form inside the #show view, then we would use #show instead of
  # #edit in the above flow.
  #
  # The downside of POST-and-replace is that the response body of step 3 will not be cached 
  # locally because it was requested via PUT and processed with the #update
  # action. To cache step 3, we should use a redirect using 
  # <tt>js_redirect edit_post_path(@post)</tt>. which isn't really a 
  # redirect because the URL is the same, but will trigger a reload via GET.
  #
  # The downside of redirecting is that this requires one additional HTTP request-response
  # cycle.
  #
  # ==== POST-and-replace with non-Ajax
  #
  # If we don't use Ajax, POST-and-replace is particularly troublesome
  # because the reload button will re-trigger the POST request, potentially
  # resulting in double-posts. Therefore, with regular HTTP, we should
  # always use POST-and-redirect.
  #
  # Ajax does not suffer from double-post issues because the POST request
  # was sent separately from the whole-page load. The reload button
  # will trigger the whole-page load (which will be the POST request
  # on regular HTTP), but not the Ajax POST request.
  #
  # Because of this, POST-and-replace is considered an Ajax optimization
  # and is not the default Kamishibai behavior.
  #
  # === POST-and-redirect for nested objects
  #
  # For example, let's look at a blog that shows a form to add comments.
  # The form is visible on the Post#show view.
  #
  # After filling in the form and submitting the comment, common Ajax
  # behavior would be to insert the comment onto the top of the
  # list of comments. This requires us to create a separate view for
  # update and create.
  #
  # With Kamishibai, we often use this pattern which resembles traditional
  # POST-and-redirect. The benefit is that we don't have to write
  # the update and create views. It's more simple.
  #
  # The downside is that there is one additional request compared
  # to the Ajax version, and we also have to render the whole page.
  #
  # However, it is still better than a complete reload because we
  # don't have to reload the JS and CSS, and the scroll position doesn't
  # change.
  #
  # If we want the regular Ajax behaviour, we must provide the ability
  # by implementing the code in ks_dom.js.coffee line 130. We will
  # then be able to prepend and append elements to containers and show
  # them using +data-+ attributes. Currently we don't support this
  # so any elements that go into data-containers is appended and
  # hidden (so that we can transition to them with KSEffect).
  #
  #     def update
  #       @comment = Comment.new(params[:comment])
  #       respond_to do |format|
  #         if @comment.save
  #           flash[:notice] = "comment was successfully created"
  #           format.js { js_redirect @comment.post }
  #         else
  #           flash[:error] = "failed to upload comment"
  #           format.html { render :edit}
  #         end
  #       end
  #     end
  #
  # ==== POST-and-redirect for nested objects with non-Ajax
  #
  # The following is how to do this with non-Ajax. The scroll position
  # will change, which might be an issue and hence should be addressed
  # by resetting the scroll position on load.
  #
  # It is very similar to the Kamishibai version.
  #
  #     def update
  #       @comment = Comment.new(params[:comment])
  #       respond_to do |format|
  #         if @comment.save
  #           flash[:notice] = "comment was successfully created"
  #           format.html { redirect_to @comment.post }
  #         else
  #           flash[:error] = "failed to upload comment"
  #           format.html { render :edit}
  #         end
  #       end
  #     end
  #
  # === POST-and-redirect with dedicated #new and #edit views
  #
  # This is the Rails pattern in the scaffold.
  #
  # We simply replace <tt>@comment.post</tt> with <tt>@comment</tt>
  # in the above code.
  #
  # Both the Rails way and the Kamishibai way are very similar.
  #
  # == Using the #redirect_with method
  #
  # Rails provides the #redirect_with method to assist rendering.
  # We have extended this so that it works well with Kamishibai.
  # Look into Kamishibai::Responder in lib/kamishibai/responder.rb.
  module Controller
    include ActionView::Helpers::JavaScriptHelper
    include KamishibaiPathHelper
    
    def self.included(base)
      base.extend(ClassMethods)
      base.before_filter :csrf_token_in_cookie
      base.before_filter :user_id_in_cookie
    end

    module ClassMethods
      # Sets the expiry time on the actions in the current controller.
      # An expiry time of 0 means that the HTTP response will not 
      # be cached. Actions that aren't set will not be cached either.
      #
      #   def PresentationController < ApplicationController
      #     set_kamishibai_expiry :index => 5, :show => 60
      #   end
      #
      # This means that the #index action response will be cached for 5 minutes
      # and the #show action will be cached for 60 seconds. All other actions,
      # i.e. #edit, #create, #update, #new, #destroy, will not be cached.
      def set_kamishibai_expiry(expiry_hash) # :doc:
        expiry_hash.each do |methods, expiry_value|
          before_filter :only => methods do |c|
            @expiry = expiry_value
          end
        end
      end
    end

    # helper_method :ksp
    private

    # Sets the csrf_token in a cookie that is accessible
    # from Javascript. Required to use csrf protection
    # in apps that cache the +head+ tag in the html body like Kamishibai.
    #
    # This is set as a #before_filter in Kamishibai::Controller
    # and you will rarely have to set it yourself.
    def csrf_token_in_cookie # :doc:
      # We set the headers directly because response.set_cookie does Base64 encoding
      # and there isn't a native Javascript method to decode it.
      response.headers["Set-Cookie"] = "csrf-token=#{form_authenticity_token}; path=/\n" + 
                                       "csrf-param=#{request_forgery_protection_token}; path=/"
    end

    # Set the user_id in the cookie so that it is available
    # from Javascript.
    def user_id_in_cookie # :doc:
      if current_user
        response.set_cookie "user_id", :value => (current_user ? current_user.id : ""), :path => "/"
      else
        response.delete_cookie "user_id"
      end
    end

    # Select the appropriate rendering template and layout settings
    # based on device used and AJAX.
    #
    # The default is to render the desktop version using
    # the regular template file (i.e. "show.html.haml").
    #
    # If the request is from a smartphone, then render
    # the regular template filename with a ".s" suffix
    # (i.e. "show.s.html.haml")
    #
    # If the request if from a galapagos device,
    # then render using the template with a ".g" suffix
    # (i.e. "show.g.html.haml"). Rendering will
    # use the #render_sjis method which will
    # encode the whole response as SJIS.
    #
    # To use the PC layout on smartphones, use
    # <tt>:smartphone => false</tt>
    #
    #     respond_to do |format|
    #       format.html{ device_selective_render }
    #     end
    #
    # We recommend that you use #device_selective_render
    # in the majority of cases. If you need to do something
    # different, then copy the source and modify as needed.
    #
    # If you want to render an action that is different from
    # the current action, then provide :action => 'target_action'
    # in the arguments.
    #
    #     format.html{ device_selective_render :action => 'target_action'}
    #
    def device_selective_render(*args) # :doc:
      options = args[0] || {}
      action = options.delete(:action) || action_name
      if request.xhr?
        options.merge!(:layout => false)
      end

      # For some reason, it seems that we lose sight of 
      # the controller_path when we Test the PosterSessionsController
      #
      # We shouldn't be doing this because the action can sometimes
      # include the controller_path. 
      #
      # action = "#{self.class.controller_path}/#{action}"

      if smartphone?
        begin
          # TODO: Try to preserve the argument format
          #       so that we can also handle partial renders

          # The options argument is modified
          # in place in the render method.
          # We therefore send a copy so that
          # we can revert to the original options
          # when we re-render.
          render "#{action}.s", options.dup
        rescue ActionView::MissingTemplate
          render "#{action}", options
        end
      elsif galapagos?
        begin
          render_sjis "#{action}.g"
        rescue ActionView::MissingTemplate
          set_utf_8_content_type
          render "#{action}", options
        end
      else
        render "#{action}", options
      end
    end

    def device_selective_redirect(*args)
      if args[0] =~ /^https?:\/\// && request.xhr?
        js_redirect args[0]
      elsif request.xhr?
        js_redirect ksp(args[0])
      else
        redirect_to *args
      end
    end

    # Redirect in Javascript
    #
    # We use this when doing a POST-then-redirect type of CRUD operation
    # in Kamishibai. 
    #
    # A regular Rails redirect_to will not change the URL and
    # hence will not cause a hashChange event. Instead, we send Javascript
    # calling <tt>kss.redirect</tt> which will change location.href
    # accordingly, and fire a hashChange event.
    #
    # The status code will be 333.
    #
    # The reason we use 333 is because according to the W3C standard
    # for XMLHttpRequest Level 1, status codes of 301, 302, 303, 307, or 308
    # are automatically redirect by the browser. This standard is not
    # followed well, and most browsers don't redirect unless the Location header
    # is set (that's why in previous versions of Kamishibai, we used 303).
    # However, IE11 has an issue with this. 
    # To prevent any futher issues, we will use 333 for Kamishibai js redirect.
    # 333 is unused as far as I know.
    # http://www.askapache.com/htaccess/apache-status-code-headers-errordocument.html
    def js_redirect(path) # :doc:
      if (path == :back) 
        js = "window.history.back()"
      else
        path = url_for(path) unless path.kind_of? String
        js = "kss.redirect('#{escape_javascript path}');"
      end
      # We specifically set content_type because we
      # often use #js_redirect inside of a MIME block
      # that expects HTML.
      response.content_type = "text/javascript"
      # Since we are using the same code to handle
      # Ajax and non-Ajax, sometimes the "Location" header
      # gets set somewhere in the middle. If we
      # leave it there, the AJAX call itself gets redirected
      # and the javascript does not reach
      # the server. That's not what we mean by our #js_redirect.
      response.headers.delete("Location")

      # The rationale for using status_code 333 is given above in
      # the comments for this method.
      #
      # jQuery automatically redirects whenever the status is
      # 301, 302, 303, 307 and raises an error whenever the final
      # status is not from 200 <= status < 300 or 304.
      # Furthermore, the response body and the headers are trashed so we can't do
      # anything about it. The only workaround is to send a status 200
      # when we want the redirect with Javascript.
      #
      # When we send a status:200, the back button
      # will come back to the redirect page instead of 
      # the page before. We can't help this.
      status_code = uses_jquery? ? 200 : 333

      render :js => js, :status => status_code
    end

    # Runs an action in the current controller and returns
    # the result as a string. Used to generate collections of
    # responses for batch updating of Kamishibai browser caches.
    # 
    # We currently modify the current request object. Instead
    # we should be creating a new request object for each 
    # call. Metal#action in metal.rb (ActionPack) should do the job.
    #
    # If however, creating a full blown request object is too much 
    # work and low-level, then we could try memoizing the current
    # request and fixing that.
    def run_action(action, request_params, options) # :doc:
      request_params.each{|key, value| params[key] = value}
      request.env['HTTP_X_REQUESTED_WITH'] = "XMLHttpRequest" if options[:xhr]
      process action
      body = response_body.first
      self.response_body = nil # prevent DoubleRenderError from occuring
      return body
    end

    # If the layout contains #default_kamishibai_hash_tag in the header,
    # the Kamishibai Javascript will check whether the current href has
    # a Kamishibai hash fragment. If a hash fragment is not set, then
    # it sets it to the default_kamishibai_hash_tag. We can ignore this
    # behavior with #ignore_default_kamishibai_hash_tag. Normally,
    # you would use this in a before filter.
    def ignore_default_kamishibai_hash_tag
      @ignore_default_kamishibai_hash_tag = true
    end

  end
end