# encoding: UTF-8

class LikesController < ApplicationController
  authorize_resource
  respond_to :html, :js
  include Kamishibai::ResponderMixin

  set_kamishibai_expiry [:my, :my_schedule, :my_votes] => 60


  # GET /likes
  # GET /likes.json
  def index
    @likes = Like.in_conference(current_conference).all
  end

  # GET /likes/1
  # GET /likes/1.json
  def show
    @like = Like.in_conference(current_conference).find(params[:id])
  end

  def by_day
    respond_to do |format|
      format.html {
        if galapagos?
          render_sjis "by_day.g"
        end
      }
    end
  end

  def my
    raise "date(:id) must be specified" unless params[:id]
    if params[:id] == "Poster"
      @likes = current_user.likes.
               in_conference(current_conference).
               includes(:presentation => {:session => :room}).
               order('presentations.starts_at ASC').
               mappable
    else  
      @date = Time.zone.parse(params[:id])
      @likes = current_user.likes.
               in_conference(current_conference).
               includes(:presentation => {:session => :room}).
               order('presentations.starts_at ASC').
               timetableable.
               presentation_on(@date)
    end
  end

  def my_schedule
    raise "date(:id) must be specified" unless params[:id]
    if params[:id] == "Poster"
      @schedules = current_user.schedules.
               includes(:presentation => {:session => :room}).
               order('presentations.starts_at ASC').
               in_conference(current_conference).
               mappable
    else
      @date = Time.zone.parse(params[:id])
      @schedules = current_user.schedules.
                   includes(:presentation => {:session => :room}).
                   order('presentations.starts_at ASC').
                   in_conference(current_conference).
                   where('presentations.starts_at > ? AND presentations.starts_at < ?', 
                          @date.beginning_of_day, @date.end_of_day)
    end
  end

  def my_votes
    # @votes = current_user.votes
    @unique_votes = current_user.votes.where(:score => Like::Vote::UNIQUE)
    @excellent_votes = current_user.votes.where(:score => Like::Vote::EXCELLENT)
  end
  # POST /likes
  # POST /likes.json
  def create
    @like = Like::Like.new(params[:like].merge(:user_id => current_user.id))
    @like.conference_confirm = current_conference
    @presentation = @like.presentation

    set_flash @like.save,
              :success => "New like was created",
              :fail => "Failed to create new like"

    respond_with @presentation, :success_action => 'presentations/social_box'
  end

  # PUT /likes/1/schedulize
  def schedulize
    @like = Like::Like.find(params[:id])
    @presentation = @like.presentation
    set_flash @like.schedulize,
              :success => "Successfully created Schedule.",
              :fail => "Failed to create Schedule."

    respond_with @presentation, :success_action => 'presentations/social_box'
  end

  # PUT /likes/1/unschedulize
  def unschedulize
    @like = Like::Schedule.find(params[:id])
    @presentation = @like.presentation
    set_flash @like.unschedulize,
              :success => "Successfully removed Schedule.",
              :fail => "Failed to removed Schedule."

    respond_with @presentation, :success_action => 'presentations/social_box'
  end

  # DELETE /likes/1
  # DELETE /likes/1.json
  def destroy
    @like = Like::Like.in_conference(current_conference).
            where(:user_id => current_user.id).find(params[:id])
    @presentation = @like.presentation
    
    set_flash @like.destroy, :success => "Like was successfully removed.",
                             :fail => "Failed to remove Like."

    respond_with @presentation, :success_action => 'presentations/social_box'
  end

  # POST /likes/vote
  # Very hackish
  def vote
    Like.transaction do
      @vote = current_user.votes.find_by_presentation_id(params[:like][:presentation_id]) ||
              false
      @presentation = Presentation.find(params[:like][:presentation_id])
      if Time.zone.now > Time.zone.parse("2013-05-31 12:00")
        flash[:error] = "Cannot vote. Voting closed on 31st, May, 12:00."
      else
        if params[:like][:score] == "0"
          @vote.destroy if @vote
          @vote = false # Because we use @vote in the response render
          flash[:notice] = "Successfully retracted vote."
        else
          if current_user.author && @presentation.authors.include?(current_user.author)
            flash[:error] = "Cannot vote to own presentation"
          else
            @vote = current_user.votes.create(params[:like]) unless @vote
            if @vote.update_attributes(params[:like].merge(:user_id => current_user.id))
              flash[:notice] = "Successfully submitted vote."
            else
              flash[:error] ||= "Failed to submit vote."
            end
          end
        end
      end
    end
    respond_to do |format|
      if request.xhr?
        format.html {render :partial => 'presentations/social_box'}
      else
        format.html { redirect_to @presentation }
      end
    end
  end

  def likes_report
    @number_of_schedules = Like::Schedule.in_conference(current_conference).count
    @number_of_likes = Like.in_conference(current_conference).count
    @number_of_liked_presentations = Presentation.in_conference(current_conference).includes(:likes).where("likes.id IS NOT NULL").count('id', :distinct => true)
    @number_of_all_presentations = Presentation.in_conference(current_conference).count
    @number_of_users_who_liked = User.in_conference(current_conference).includes(:likes).where("likes.id IS NOT NULL").count('id', :distinct => true)
    @number_of_all_users = User.in_conference(current_conference).count
    @number_of_logined_users = User.in_conference(current_conference).where('login_count > 0').count
    @users_who_failed_to_log_in = User.in_conference(current_conference).where('failed_login_count > 0 AND login_count = 0')
    @top_likes = Presentation.
                   in_conference(current_conference).
                   select('presentations.*, count(*) as count').
                   joins(:session => :conference). #INNER JOIN??
                   joins(:likes).group('presentations.id').
                   order('count(*) DESC').limit(50)
    @top_schedules = Presentation.
                       in_conference(current_conference).
                       select('presentations.*, count(*) as count').
                       joins(:session => :conference). #INNER JOIN??
                       joins(:schedules).group('presentations.id').
                       order('count(*) DESC').limit(50)
  end

  def votes_report
    @number_of_all_users = User.count
    @total_number_of_voters = User.with_role('voter').count
    @number_of_voters_who_havent_voted = User.with_role('voter').includes(:votes).where('likes.id IS NULL').count
    @top_excellents = Like::Vote.select("likes.*, count(*) as count, presentations.submission_id as submission_id").joins(:presentation).
                                 where(:score => Like::Vote::EXCELLENT).group('presentations.submission_id').order('count(*) DESC').limit(10)
    @number_of_excellent_votes = Like::Vote.where(:score => Like::Vote::EXCELLENT).count
    @top_uniques = Like::Vote.select("likes.*, count(*) as count, presentations.submission_id as submission_id").joins(:presentation).
                                 where(:score => Like::Vote::UNIQUE).group('presentations.submission_id').order('count(*) DESC').limit(10)
    @number_of_unique_votes = Like::Vote.where(:score => Like::Vote::UNIQUE).count
    
  end

end
