module Ponzu
  # Provides the `current_user` method in the controller and
  # the `current_user` helper method for the views.
  #
  # It also provides the `require_login` method that 
  # you can use in `before_filter` to restrict access.
  module Authentication
    def self.included(base)
      base.helper_method :current_user
    end

    private

    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      # http://www.rubydoc.info/gems/authlogic/3.4.3/Authlogic/AuthenticatesMany
      @current_user_session = current_conference.user_sessions.find
    end

    def current_user
      @current_user = current_user_session && current_user_session.record
    end

    def require_login
      unless current_user
        flash[:error] = "You must be logged in to use this system"
        redirect_to login_path
      end
    end
    
  end
end