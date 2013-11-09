module Kamishibai
  # Based on http://stackoverflow.com/questions/366311/how-do-you-handle-rails-flash-with-ajax-requests
  #
  # The Kamishibai::Flash module allows us to use the Flash
  # mechanism on Ajax calls.
  #
  # Simply set the flash as normal, and the message will
  # be sent to the browser via HTTP headers in the response,
  # and the browser will handle it through Kamishiba.js.
  #
  # Unlike regular Flash which shows up on the next request,
  # the Ajax flash will show up immediately after
  # receiving the response. This is because regular Flash
  # is built for the update-then-redirect scheme, whereas
  # with Ajax, we don't need the redirect.
  module Flash
    
    def self.included(base)
      base.after_filter :flash_to_headers

      base.extend(ClassMethods)
    end

    module ClassMethods
    end

    private

    def flash_to_headers
      return unless request.xhr?
      # Rails #to_json always converts non-ascii so we use that
      # to send non-ascii via the headers.
      response.headers['X-Message'] = flash_message.to_json
      response.headers["X-Message-Type"] = flash_type.to_s

      flash.discard # don't want the flash to appear when you reload page
    end

    def flash_message
      [:error, :warning, :notice].each do |type|
        return flash[type] unless flash[type].blank?
      end
      return ""
    end

    def flash_type
      [:error, :warning, :notice].each do |type|
        return type unless flash[type].blank?
      end
      return ""
    end

    # Shortcut for setting flash
    # Usage:
    #   set_flash @user.save, :success => "User saved.", :fail => "Failed to save user"
    #
    # Note:
    #   Flash should be used for short messages only.
    #   If we want to return the validation errors, we should embed that in the HTML response.
    def set_flash success, messages
      raise "must set :success and :fail messages" if (messages[:success].blank? || messages[:fail].blank?)
      if success
        flash[:notice] = messages[:success]
      else
        flash[:error] = messages[:fail]
      end
    end
  end
end