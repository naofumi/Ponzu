class SubmissionsController < ApplicationController
  authorize_resource
  respond_to :html, :js
  include Kamishibai::ResponderMixin

  # GET /submissions
  # GET /submissions.json
  def index
    @submissions = Submission.in_conference(current_conference).
                              paginate(:page => params[:page])

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /submissions/1
  # GET /submissions/1.json
  def show
    @submission = Submission.in_conference(current_conference).
                             find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @submission }
    end
  end

  # GET /submissions/new
  # GET /submissions/new.json
  def new
    @submission = Submission.new
    if params[:session_id]
      @submission.submission_number = "#{params[:session_id]}-"
    end

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @submission }
    end
  end

  # GET /submissions/1/edit
  def edit
    @submission = Submission.in_conference(current_conference).
                             find(params[:id])
    verify_ownership(@submission)
  end

  # POST /submissions
  # POST /submissions.json
  def create
    @submission = Submission.new(params[:submission])
    verify_ownership(@submission)
    @submission.conference_confirm = current_conference
    @submission.skip_authorships_and_institutions_validations
    # success = false
    Submission.transaction do
      begin
        @submission.save!
        @submission.reload
        if params[:session_id]
          session = Session.find(params[:session_id])
          @presentation = Presentation.create!(:session_id => session.id, 
                                               :submission_id => @submission.id,
                                               :starts_at => session.starts_at)
        end    
        # success = true
        flash[:notice] = "Submission was successfully created."
      rescue
        # success = false
        flash[:error] = "Failed to create submission."
      end
    end

    respond_with @submission, :success_action => :back
  end

  # PUT /submissions/1
  # PUT /submissions/1.json
  def update
    @submission = Submission.in_conference(current_conference).
                             find(params[:id])
    verify_ownership(@submission)
    @submission.do_not_validate_title_abstract_lengths = true

    if @submission.update_attributes(params[:submission])
      flash[:notice] = "Submission was successfully updated."
    else
      flash[:error] = "Failed to update Submission."
    end

    respond_with @submission, :success_action => :back
  end

  def update_institutions
    @submission = Submission.in_conference(current_conference).
                             find(params[:id])
    verify_ownership(@submission)

    if @submission.update_attributes(params[:submission])
      flash[:notice] = "Submission was successfully updated."
    else
      flash[:error] = "Failed to update Submission."
    end

    respond_with @submission, :success_action => :edit
  end

  # DELETE /submissions/1
  # DELETE /submissions/1.json
  def destroy
    @submission = Submission.in_conference(current_conference).
                             find(params[:id])
    if @submission.destroy
      flash[:notice] = "Submission was successfully destroyed."
    else
      flash[:error] = "Failed to destroy Submission #{@submission.errors.full_messages}"
    end

    respond_with @submission, :success_action => :back, :action => :edit
  end

  private

  def verify_ownership(submission)
    return true if can?(:moderate, submission)
    unless current_user.author &&
           submission.authors.include?(current_user.author)
      raise CanCan::AccessDenied, "Current user cannot access."
    end
  end
end
