class UserSessionsController < ApplicationController
  authorize_resource :except => [:new, :create, :switch]
  respond_to :html, :js
  include Kamishibai::ResponderMixin
  before_filter :ignore_default_kamishibai_hash_tag
  
  def new
    if set_manifest
      @set_manifest = true
    end

    @user_session = UserSession.new

    respond_with @user_session
  end
  
  # Create a new user session (login).
  #
  # Never call this via AJAX because the cookies
  # will get confused and the login status may not
  # get set correctly.
  def create
    @user_session = current_conference.user_sessions.new(params[:user_session])
    if @user_session.save
      flash[:notice] = t("error_messages.login_succeeded")
    else
      flash[:error] = t("error_messages.login_failed")
    end
    # Set the user_id in the cookie.
    # This normally runs as a :before_filter, but
    # in the current case, we have to rerun it because
    # we have changed the user_id in this action.
    # user_id_in_cookie(@user_session.record)
    respond_with @user_session, :location => "/"

    # if @user_session.save
    #   flash[:notice] = "Successfully logged in."
    #   redirect_to root_path
    # else
    #   if smartphone?
    #     render "new.s", :layout => "layouts/smartphone"
    #   elsif galapagos?
    #     render_sjis "new.g", :layout => "layouts/galapagos"
    #   else
    #     render "new"
    #   end
    # end
  end

  # Switch users
  # For demo purposes only
  def switch
    unless current_conference.tag == 'ponzu_tag'
      raise "User switch only available on demo conference"
    end
    @user_session = current_conference.user_sessions.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Successfully logged in."
    else
      flash[:error] = "Failed to log in."
    end

    respond_with @user_session, :location => "/"
  end
  
  def destroy
    @user_session = current_conference.user_sessions.find
    @user_session.destroy
    flash[:notice] = "Successfully logged out."
    redirect_to login_path
  end
end
