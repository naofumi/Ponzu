class MeetUpCommentsController < ApplicationController
  authorize_resource :except => [:show]
  respond_to :html, :js, :json
  include Kamishibai::ResponderMixin

  before_filter do |c|
    @menu = :meet_ups
  end
  # GET /meet_up_comments
  # GET /meet_up_comments.json
  def index
    @meet_up_comments = MeetUpComment.in_conference(current_conference).all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /meet_up_comments/1
  # GET /meet_up_comments/1.json
  def show
    @meet_up_comment = MeetUpComment.in_conference(current_conference).
                                     find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /meet_up_comments/new
  # GET /meet_up_comments/new.json
  def new
    @meet_up_comment = MeetUpComment.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /meet_up_comments/1/edit
  def edit
    @meet_up_comment = MeetUpComment.in_conference(current_conference).
                                     find(params[:id])
  end

  # POST /meet_up_comments
  # POST /meet_up_comments.json
  def create
    @meet_up_comment = MeetUpComment.new(params[:meet_up_comment])
    @meet_up_comment.user = current_user
    # We don't need to set @meet_up_comment.conference_confirm
    # because the user will always be set to the current user
    # and #meet_up_and_user_conferences_must_match validation
    # on MeetUpComment will ensure that the meet_up will also
    # belong to the same conference.

    respond_to do |format|
      if @meet_up_comment.save
        @meet_up = @meet_up_comment.meet_up
        flash[:notice] = "Comment was successfully created."
        if request.xhr?
          format.html { render :partial => "meet_ups/meet_up_comments" }
        else
          format.html {redirect_to @meet_up }          
        end
      else
        flash[:error] = "Failed to create comment"
        format.html { render :edit }
      end
    end
  end

  # PUT /meet_up_comments/1
  # PUT /meet_up_comments/1.json
  def update
    @meet_up_comment = MeetUpComment.find(params[:id])
    @meet_up_comment.user = current_user
    # We don't need to set @meet_up_comment.conference_confirm
    # because the user will always be set to the current user
    # and #meet_up_and_user_conferences_must_match validation
    # on MeetUpComment will ensure that the meet_up will also
    # belong to the same conference.

    respond_to do |format|
      if @meet_up_comment.update_attributes(params[:meet_up_comment])
        flash[:notice] = 'Meet up comment was successfully updated.'
        format.html { render :show }
      else
        flash[:error] = 'Failed to update meetup comment.'
        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /meet_up_comments/1
  # DELETE /meet_up_comments/1.json
  def destroy
    @meet_up_comment = current_user.meet_up_comments.
                                    in_conference(current_conference).
                                    find(params[:id])
    @meet_up_comment.destroy
    @meet_up = @meet_up_comment.meet_up

    respond_to do |format|
      if request.xhr?
        format.html { render :partial => "meet_ups/meet_up_comments" }
      else
        format.html {redirect_to @meet_up }          
      end
    end
  end
end
