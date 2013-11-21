# encoding: UTF-8

class UsersController < ApplicationController
  authorize_resource
  respond_to :html, :js
  include Kamishibai::ResponderMixin

  set_kamishibai_expiry [:show] => 1 * 60 * 60


  before_filter do |c|
    @menu = :home
    # @expiry = 60 * 60 # seconds
  end

  # GET /users
  # GET /users.json
  def index
    authorize! :see_other, User
    if params[:query].blank?
      @users = User.in_conference(current_conference).order("users.id").paginate(:page => params[:page], :per_page => 30)
    else
      tokens = params[:query].split(/ |　/)
      @users = User.in_conference(current_conference).order("users.id").paginate(:page => params[:page], :per_page => 30)
      tokens.each do |t|
        @users = @users.where("jp_name LIKE ? OR en_name LIKE ?", "%#{t}%", "%#{t}%")
      end
    end

    if params[:has_author] == '1'
      @users = @users.includes(:author).where("authors.id IS NOT NULL")
    end
    if params[:has_no_author] == '1'
      @users = @users.includes(:author).where("authors.id IS NULL")
    end

    @users = @users.in_conference(current_conference)

    respond_with @users
  end

  # GET /users/1
  # GET /users/1.json
  def show
    @user = User.in_conference(current_conference).find(params[:id])
    if @user.author
      device_selective_redirect @user.author
    else
      respond_with @user
    end
  end

  # GET /users/new
  # GET /users/new.json
  def new
    @user = User.new
    @user.jp_name = params[:jp_name] if params[:jp_name]
    @user.en_name = params[:en_name] if params[:en_name]
    @user.login = params[:login] if params[:login]

    respond_with @user
  end

  # GET /users/1/edit
  def edit
    if can? :see_other, User
      @user = User.in_conference(current_conference).find(params[:id])
    else
      @user = current_user
    end
    respond_to do |format|
      format.html {
        if request.xhr?
          render :layout => false
        end
      }
    end
  end

  # POST /users
  # POST /users.json
  def create
    authorize! :create, User
    @user = User.new(params[:user])
    @user.conference_confirm = current_conference

    if @user.save
      flash[:notice] = 'User was successfully created.'
    else
      flash[:error] = 'Failed to create User.'
    end

    respond_with @user
  end

  # PUT /users/1
  # PUT /users/1.json
  def update
    if can? :see_other, User
      @user = User.in_conference(current_conference).find(params[:id])
    else
      @user = current_user
    end
    
    if @user.update_attributes(params[:user])
      flash[:notice] = 'User was successfully updated.'
    else
      flash[:error] = "Failed to update user."
    end

    respond_with @user, :location => edit_user_path(@user)
  end

  # DELETE /users/1
  # DELETE /users/1.json
  def destroy
    @user = User.in_conference(current_conference).find(params[:id])
    @user.destroy

    if @user.destroyed?
      flash[:notice] = "User was successfully deleted."
    else
      flash[:error] = "Failed to delete user."
    end

    respond_with @user, :location => users_path
  end

  def settings
    @user = current_user

    respond_with @user
  end

  # Deprecated
  def edit_name
    @user = current_user
    respond_to do |format|
      if smartphone?
        format.html{ render "#{__method__}.s", :layout => "layouts/smartphone"}
      elsif galapagos?
        format.html{ render_sjis "#{__method__}.g", :layout => "layouts/galapagos"}
      else
        format.html{ render "#{__method__}", :layout => "layouts/login"}
      end
    end
  end

  # Deprecated
  def update_name
    @user = current_user
    respond_to do |format|
      if @user.update_attributes(params[:user])
        logger.info @user.inspect
        format.html {redirect_to root_path}
      else
        if smartphone?
          format.html{ render "edit_name.s", :layout => "layouts/smartphone" }
        elsif galapagos?
          format.html{ render_sjis "edit_name.g", :layout => "layouts/galapagos" }
        else
          format.html{ render "edit_name", :layout => "layouts/login" }
        end
      end
    end
  end

  def update_settings
    @user = current_user
    if @user.update_attributes(params[:user])
      flash[:notice] = "Settings were sucessfully updated."
    else
      flash[:error] = "Failed to update settings."
    end

    respond_with @user, :location => settings_user_path(@user), 
                        :action => :settings
  end
  
  # Pending
  def set_global_message_to_read
    @user = current_user
    @global_message = GlobalMessage.find(params[:global_message_id])
    @user.set_global_message_to_read(@global_message)
    respond_to do |format|
      if request.xhr?
        format.html { render :partial => 'dashboard/global_messages' }
      else
        format.html { redirect_to :back }
      end
    end
  end
  
  # Pending
  def reset_read_global_messages
    @user = current_user
    @user.reset_read_global_messages
    respond_to do |format|
      if request.xhr?
        format.html { render :partial => 'dashboard/global_messages' }
      else
        format.html { redirect_to :back }
      end
    end
  end

  # Deprecated
  def admin_search_by_registration_id
    @registration_id = params[:registration_id]
    @user = User.find_by_login(@registration_id)
    if @user
      render :js => "kss.redirect('#{ksp(admin_panel_user_path(@user))}')" 
    else
      render :js => "KSApp.notify('#{@registration_id} not found')"
    end
  end

  # Deprecated
  def admin_search
    @query = query = params[:query]
    if !query.blank?
      if params[:type].blank? || params[:type] == 'users'
        @users = User.search do
          fulltext query do
            boost_fields :en_name => 2.0, :jp_name => 2.0,
                         :authorship_en_name => 1.5, :authorship_jp_name => 1.5
          end
          paginate :page => params[:page], :per_page => 20
        end
      end
    end
    render :layout => false
  end

  # Deprecated
  def admin_panel
    @user = User.find(params[:id])
    render :layout => false
  end
end
