class TimetableController < ApplicationController
  authorize_resource :class => Session::TimeTableable
  respond_to :html, :js
  include Kamishibai::ResponderMixin

  before_filter do |c|
    @menu = :sessions
  end

  set_kamishibai_expiry [:show, :list, :like_highlights] => 24 * 60 * 60

  def container
    raise "deprecated"
    render :layout => false
  end
  
  # GET /timetable/2011-12-14
  def show
    date_string = params[:id] || raise("Must set date for timetable")

    @show_date = Time.zone.parse(date_string)
    @sessions = Session::TimeTableable.all_in_day(@show_date).
                  in_conference(current_conference).
                  includes(:room).all

    # respond_with currently doesnt work with JSON requests.
    # respond_with @sessions
  end

  def list
    date_string = params[:id] || '2011-12-14'

    @show_date = Time.parse(date_string)
    
    @sessions = Session::TimeTableable.all_in_day(@show_date).
                  in_conference(current_conference).
                  includes(:room).order("sessions.starts_at, CONVERT(SUBSTRING(rooms.en_name,6), UNSIGNED)").all
                  
    @sessions = @sessions.select{|s| !s.is_poster?}

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
    respond_to do |format|
      format.html {
        if request.xhr?
          if smartphone?
            render "list.s", :layout => false
          else
            render :layout => false
          end
        else
          if galapagos?
            render_sjis "#{__method__}.g"
          else
            render
          end
        end
      }
    end
  end

  # GET /timetable/2011-12-14/like_highlights
  def like_highlights
    date_string = params[:id] || raise("Must set date for timetable")

    @show_date = Time.parse(date_string)
    if current_user
      @likes = current_user && current_user.likes.includes(:presentation).
                 where('presentations.starts_at' => @show_date.beginning_of_day..@show_date.end_of_day).
                 timetableable
    else
      render nothing: true
      return
    end

    respond_with @likes
  end
end
