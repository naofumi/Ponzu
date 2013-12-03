class PosterSessionsController < ApplicationController
  authorize_resource :class => Session::Poster
  respond_to :html, :js
  include Kamishibai::ResponderMixin
  begin
    include PosterSessionTestAction
    rescue
  end

  before_filter do |c|
    @menu = :posters
    @zoom = 1
  end

  set_kamishibai_expiry [:show, :list] => 24 * 60 * 60,
                        [:like_highlights, :list_highlights] => 24 * 60 * 60

  def container
    render :layout => false
  end
  
  def show
    date_string = params[:id] || raise("must set date for poster session show")
    @show_date = Time.parse(date_string)
    
    @sessions = Session::Poster.in_conference(current_conference).
                                all_in_day(@show_date).all
    respond_with @sessions
  end

  def list
    date_string = params[:id] || raise("must set date for poster session show")
    @show_date = Time.parse(date_string)
    
    @sessions = Session::Poster.in_conference(current_conference).
                                all_in_day(@show_date).all

    # For galapagos, we render the "likes" indicators in the same request,
    # whereas for desktops and smartphones, we set the indicators in a
    # separate Ajax response
    if galapagos?
      @likes = current_user ? current_user.likes.includes(:presentation).
                                    where("presentations.session_id" => @sessions) : 
                              []
      @schedules = current_user ? current_user.schedules.includes(:presentation).
                                     where("presentations.session_id" => @sessions) : 
                                  []
    end

    respond_with @sessions
    # params[:id] ||= 1
    # @day = params[:id]
    
    # @sessions = Session::Mappable.where("sessions.number LIKE ? OR sessions.number LIKE ?", "#{params[:id]}P%", "#{params[:id]}LBA%")

    # respond_to do |format|
    #   format.html {
    #     if request.xhr?
    #       if smartphone?
    #         render "list.s", :layout => false
    #       else
    #         render :layout => false
    #       end
    #     else
    #       if galapagos?
    #         render_sjis "#{__method__}.g"
    #       else
    #         render
    #       end
    #     end
    #   }
    # end
  end

  def list_highlights
    date_string = params[:id] || raise("must set date for poster session show")
    @show_date = Time.parse(date_string)
    
    @sessions = Session::Poster.
                in_conference(current_conference).
                all_in_day(@show_date).all
    if current_user
      @likes = current_user.likes.includes(:presentation).
                          where("presentations.session_id" => @sessions)
      @schedules = current_user.schedules.includes(:presentation).
                               where("presentations.session_id" => @sessions)
    else
      @likes, @schedules = [], []
    end

    respond_with @sessions

  end

  # GET /poster_sessions/s/like_highlights
  def like_highlights
    date_string = params[:id] || raise("must set date for poster session show")
    @show_date = Time.parse(date_string)
    
    @sessions = Session::Poster.
                in_conference(current_conference).
                all_in_day(@show_date).all

    if current_user 
      @likes = current_user.likes.includes(:presentation).
               where("presentations.session_id" => @sessions)
      @schedules = current_user && current_user.schedules.includes(:presentation).
               where("presentations.session_id" => @sessions)
    else
      @likes = []
      @schedules = []
    end

    respond_with @sessions
  end

end
