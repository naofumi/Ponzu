# encoding: UTF-8

class PonzuController < ActionController::Base
  include Kamishibai::Controller
  include Kamishibai::DeviceSupport
  include Kamishibai::LocaleSupport
  include Kamishibai::Cache
  include Kamishibai::Menu
  include Kamishibai::Flash
  # include ConferenceStrings #deprecated
  include Ponzu::MultiConference

  protect_from_forgery

  helper_method :current_user
  before_filter :edit_name_if_generic
  before_filter :load_single_table_inheritance
  # before_filter :require_login

  unless false #Rails.configuration.consider_all_requests_local
    rescue_from Exception do |exception|
      render :file => "#{Rails.root}/public/500.html", :layout => false, :status => 500
      raise exception # We want the error logs
    end

    rescue_from ActiveRecord::RecordNotFound do |exception|
      render :file => "#{Rails.root}/public/404.html", :layout => false, :status => 404
    end

    rescue_from CanCan::AccessDenied do |exception|
      render :file => "#{Rails.root}/public/422.html", :layout => false, :status => 422
    end
  end

  protected

  private

  def edit_name_if_generic
    if current_user && 
         (current_user.jp_name =~ /招待者/ || current_user.jp_name =~ /on-site/) &&
         current_user.registrant && 
         request.original_fullpath != edit_name_user_path(current_user) &&
         request.original_fullpath != update_name_user_path(current_user)
      redirect_to edit_name_user_path(current_user)
    end
  end

  def set_manifest
    Rails.application.config.use_manifest
  end

  def require_login
    unless current_user
      flash[:error] = "You must be logged in to use this system"
      redirect_to login_path
    end
  end
  
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    @current_user = current_user_session && current_user_session.record
  end

  def load_single_table_inheritance
    # Notes on Single Table Inheritance
    # http://www.christopherbloom.com/2012/02/01/notes-on-sti-in-rails-3-0/
    # http://www.alexreisner.com/code/single-table-inheritance-in-rails
    #
    # We have to load the subclass of the models directly because the
    # development environment will only do it lazily.
    # The original articles loaded in the config/initializers but
    # I think Rails is getting lazier. I put these in before_filters
    if Rails.env.development?
      %w[presentation session].each do |dir|
        dir_path = File.join(Ponzu::Engine.root, "app","models", dir)
        require_dependency dir_path
        files = Dir.entries(dir_path).select{|fn| fn =~ /\.rb$/}
        files.each do |file|
          require_dependency File.join(dir_path, file)
        end
      end
    end
  end

end
