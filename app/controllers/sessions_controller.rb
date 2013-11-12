class SessionsController < ApplicationController
  authorize_resource
  respond_to :html, :js, :json
  include Kamishibai::ResponderMixin
  
  before_filter do |c|
    @menu = :sessions
  end

  set_kamishibai_expiry [:show, :batch_request_liked_sessions] => 24 * 60 * 60,
                        [:social_box, :poster_social_box] => 1 * 60


  # GET /sessions
  # GET /sessions.json
  def index
    @sessions = Session.order(:number).
                in_conference(current_conference).
                paginate(:page => params[:page], :per_page => 30)
  end

  # TODO: Set up Nginx
  # Looked around the web, but I think that there is a lot of outdated info.
  # Nginx.conf has sendfile on by default.
  # For rails, I think that I simply have to uncomment in config/production.rb
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect'
  def download_pdf
    @session = Session.find(params[:id])
    send_file("#{Rails.root}/indesign_auto_pdfs/#{conference_tag}/#{@session.number}_en.pdf",
              :filename => "#{conference_tag}_#{@session.number}.pdf",
              :disposition => "inline")
  end

  def download_full_day_pdf
    raise if Rails.env == "production" && Time.now < Time.local(2012,11,29)
    @session = Session.find(params[:id])
    locale = ['en', 'ja'].detect{|l| l == params[:locale]} # sanitize
    session_number = @session.number
    day = session_number[0,1]
    headers['X-Accel-Buffering'] = "no"
    headers['Content-Length'] = File.size("#{Rails.root}/indesign_auto_pdfs/#{day}_#{locale}.pdf").to_s
    send_file("#{Rails.root}/indesign_auto_pdfs/#{day}_#{locale}.pdf",
              :filename => "#{conference_tag}-day-#{day}_#{locale}.pdf",
              :disposition => "attachment")
  end

  def download_full_pdf
    file_path = "#{Rails.root}/indesign_auto_pdfs/#{conference_tag}_all.pdf"
    headers['X-Accel-Buffering'] = "no"
    headers['Content-Length'] = File.size(file_path).to_s
    send_file(file_path,
              :filename => "#{conference_tag}_all.pdf",
              :disposition => "attachment")
  end

  # GET /sessions/1
  # GET /sessions/1.json
  def show
    @session = Session.in_conference(current_conference).
                       find(params[:id])
    @menu = @session.is_poster? ? :posters : :sessions

    @show_date = @session.starts_at

    @presentations = @session.presentations.paginate(:page => params[:page], :per_page => 30)
  end

  # List booth presentations specified by params[:booth_nums]
  def query
    @presentations = Presentation.in_conference(current_conference).
                     where(:booth_num => params[:bns]).
                     order(:booth_num).
                     paginate(:page => params[:page], :per_page => 30)
    @session = @presentations.first.session
    device_selective_render :action => "show"
  end

  # PUT /sessions/1/order_presentations_by_number
  def order_presentations_by_number
    @session = Session.in_conference(current_conference).
                       find(params[:id])

    set_flash @session.order_presentations_by_number,
              :success => 'Presentations were successfully reordered.',
              :fail => 'Failed to reorder presentations.'
    respond_with @session, :success_action => :edit
  end

  # PUT /sessions/1/set_presentation_duration?duration=10
  def set_presentation_duration
    @session = Session.in_conference(current_conference).
                       find(params[:id])
    set_flash @session.set_presentation_times_by_duration(params[:duration].to_f),
              :success => "Successfully modified presentation times.",
              :fail => "Failed to modify presentation times."
    respond_with @session, :success_action => :edit
  end

  # Deprecated?
  def social_box
    raise "Do we use this? If not, deprecate and remove associated views and routes."
    @session = Session.in_conference(current_conference).
                       find(params[:id])
    respond_to do |format|
      if request.xhr?
        format.html {
          render :partial => "sessions/social_box"
        }
      end
    end
  end

  # Deprecated?
  def poster_row
    raise "I thought that this was deprecated"
    @day, first_slot, last_slot = params[:id].split('_').map{|p| p.to_i}
    @first_slot, @last_slot = [first_slot, last_slot].sort
    @first_number, @last_number = [first_slot, last_slot].map{|n| "#{@day}P-#{sprintf('%04d', n)}"}
    @presentations = Presentation.where("presentations.number >= ? AND " +
                                  "presentations.number <= ?", @first_number, @last_number)
    @menu = :posters

    @poster_hall = PosterHall.new(:zoom => @zoom)

    respond_to do |format|
      format.html {
        if request.xhr?
          if smartphone?
            render "poster.s", :layout => false
          else
            render "poster", :layout => false
          end
        end
      }
    end
  end

  # Deprecated?
  def poster_social_box
    raise "I thought that this was deprecated"
    @day, first_slot, last_slot = params[:id].split('_').map{|p| p.to_i}
    @first_slot, @last_slot = [first_slot, last_slot].sort
    @first_number, @last_number = [first_slot, last_slot].map{|n| "#{@day}P-#{sprintf('%04d', n)}"}
    @presentations = Presentation.conference_in(current_conference).
                                  where("presentations.number >= ? AND " +
                                        "presentations.number <= ?", @first_number, @last_number)
    respond_to do |format|
      format.html {
        if request.xhr?
          render :partial => "sessions/poster_social_box"
        end
      }
    end
  end

  # GET /sessions/new
  # GET /sessions/new.json
  def new
    @session = Session.new
  end

  # GET /sessions/1/edit
  def edit
    @session = Session.in_conference(current_conference).
                       find(params[:id])
  end

  # POST /sessions
  # POST /sessions.json
  def create
    type_name = params[:session].delete(:type)
    @session = Session.new(params[:session])
    @session.type = type_name.constantize.to_s # constantize to sanitize
    @session.conference_confirm = current_conference

    set_flash @session.save,
              :success => 'Session was successfully created.',
              :fail => 'Failed to create Session.'

    respond_with @session
  end

  # PUT /sessions/1
  # PUT /sessions/1.json
  def update
    type_name = params[:session].delete(:type)
    @session = Session.in_conference(current_conference).
                       find(params[:id])
    @session.type = type_name.constantize.to_s # constantize to sanitize

    set_flash @session.update_attributes(params[:session]),
              :success => 'Session was successfully updated.',
              :fail => 'Failed to update Session.'

    respond_with @session do |format| 
      format.html{ render action: 'edit'}
    end
  end

  # DELETE /sessions/1
  # DELETE /sessions/1.json
  def destroy
    @session = Session.in_conference(current_conference).
                       find(params[:id])

    set_flash @session.destroy,
              :success => "Session was successfully destroyed.",
              :fail => "Session could not be destroyed."

    respond_with @session
  end

  def batch_request_liked_sessions
    unless current_user
      render(:json => [])
      return
    end
    @likes = current_user.likes.includes(:presentation => :session)
    @sessions = @likes.map{|l| l.presentation.session}.uniq
    exclude_paths = params[:exclude_paths] || []

    respond_to do |format|
      fragments = {}
      if !galapagos?
        @sessions.each do |s|
          fragments.merge!(json_responses_for_session(s, exclude_paths))
        end
      end

      format.json { render :json => fragments }
    end
  end

  private

  def json_responses_for_session(session, exclude_paths)
    fragments = {}
    # Same as SessionContrller#show
    @session = session
    @menu = @session.is_poster? ? :posters : :sessions
    @show_date = @session.starts_at

    path = session_path(@session, :locale => locale)
    unless exclude_paths.include?(path)
      fragments[path] = render_to_string("show#{".s" if smartphone?}", :formats => [:html], :layout => false)
    end
    fragments
  end

end
