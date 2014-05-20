class BoothSessionsController < ApplicationController
  authorize_resource :class => Session::Booth
  respond_to :html, :js
  include Kamishibai::ResponderMixin

  begin
    include BoothSessionTestAction
    rescue
  end

  before_filter do |c|
    @menu = :booths
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

    @sessions = Session::Booth.in_conference(current_conference)
    respond_with @sessions
  end

  def list
    date_string = params[:id] || raise("must set date for booth session show")
    @show_date = Time.parse(date_string)

    @sessions = Session::Booth.in_conference(current_conference)

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
  end

  def list_highlights
    date_string = params[:id] || raise("must set date for booth session show")
    @show_date = Time.parse(date_string)

    @sessions = Session::Booth.
                in_conference(current_conference)
    if current_user
      @likes = current_user.likes.includes(:presentation).
                          where("presentations.session_id" => @sessions)
      @schedules = current_user.schedules.includes(:presentation).
                               where("presentations.session_id" => @sessions)
    else
      render nothing: true
      return
    end
    device_selective_render :action => 'poster_sessions/list_highlights'
  end

  # GET /poster_sessions/s/like_highlights
  def like_highlights
    date_string = params[:id] || raise("must set date for booth session show")
    @show_date = Time.parse(date_string)
    
    @sessions = Session::Booth.
                in_conference(current_conference)

    if current_user 
      @likes = current_user.likes.includes(:presentation).
               where("presentations.session_id" => @sessions)
      @schedules = current_user && current_user.schedules.includes(:presentation).
               where("presentations.session_id" => @sessions)
    else
      @likes = []
      @schedules = []
    end

    @test = params[:test]
    if @test
      bgm = "BoothMap::#{current_conference.module_name}".constantize.new
      booth_numbers = bgm.marker.keys
      presentations = Presentation.where(:booth_num => booth_numbers)
      @likes = presentations.map{|p| Like::Like.new(:presentation => p, :user => current_user)}
    end

    respond_with @sessions
  end

end
