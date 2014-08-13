class MeetUpsController < ApplicationController
  authorize_resource :except => [:index, :show]
  respond_to :html, :js, :json
  include Kamishibai::ResponderMixin

  set_kamishibai_expiry [:index, :show] => 1

  before_filter do |c|
    @menu = :meet_ups
  end

  # GET /meet_ups
  # GET /meet_ups.json
  def index
    @show_date = params[:date] ? Time.parse(params[:date]) :
                                 current_conference.closest_date_for(:meet_up, Time.zone.now)
    @meet_ups = MeetUp.where("? < starts_at AND starts_at < ?",
                        @show_date.beginning_of_day,
                        @show_date.end_of_day).paginate(:page => params[:page]).
                       in_conference(current_conference)
    
    respond_with @meet_ups
  end

  # GET /meet_ups/1
  # GET /meet_ups/1.json
  def show
    @meet_up = MeetUp.in_conference(current_conference).
                      find(params[:id])

    respond_with @meet_up
  end

  # GET /meet_ups/new
  # GET /meet_ups/new.json
  def new
    @meet_up = MeetUp.new

    respond_with @meet_up
  end

  # GET /meet_ups/1/edit
  def edit
    @meet_up = MeetUp.in_conference(current_conference).
                      find(params[:id])
    if @meet_up.owner_id != current_user.id
      raise CanCan::AccessDenied.new("Not authorized!", :read, @meet_up)
    end

    respond_with @meet_up
  end

  # POST /meet_ups
  # POST /meet_ups.json
  def create
    @meet_up = MeetUp.new(params[:meet_up])
    @meet_up.owner_id = current_user.id
    @meet_up.conference_confirm = current_conference

    if @meet_up.save
      flash[:notice] = "Successfully created Yoruzemi"
      ks_cache_invalidate [meet_ups_path(:date => @meet_up.starts_at.strftime('%Y-%m-%d'))]
    else
      flash[:error] = "Failed to create Yoruzemi"
    end
    respond_with @meet_up
  end

  # PUT /meet_ups/1
  # PUT /meet_ups/1.json
  def update
    params[:meet_up].delete('owner_id')
    @meet_up = MeetUp.in_conference(current_conference).
                      find(params[:id])
    old_starts_at = @meet_up.starts_at
    if @meet_up.owner_id != current_user.id
      raise CanCan::AccessDenied.new("Not authorized!", :read, @meet_up)
    end

    if @meet_up.update_attributes(params[:meet_up])
      flash[:notice] = "Yoruzemi was successfully updated."
      # We also have to invalidate the old starts_at
      ks_cache_invalidate [meet_ups_path(:date => @meet_up.starts_at.strftime('%Y-%m-%d')),
                           meet_ups_path(:date => old_starts_at.strftime('%Y-%m-%d')) ]

    else
      flash[:error] = "Failed to update yoruzemi"
    end

    respond_with @meet_up
  end

  # DELETE /meet_ups/1
  # DELETE /meet_ups/1.json
  #
  # Currently, only admins can destory meet_ups
  def destroy
    @meet_up = MeetUp.in_conference(current_conference).
                      find(params[:id])
    @meet_up.destroy

    if @meet_up.destroyed?
      flash[:notice] = "Sucessfully destroyed meet up"
    else
      flash[:error] = "Failed to destroyed meet up"
    end
    respond_with @meet_up
  end
  
  # PUT /meet_ups/1/participate
  def participate
    @meet_up = MeetUp.in_conference(current_conference).
                      find(params[:id])
    @user = current_user
    @meet_up.toggle_participation(@user)
    
    respond_to do |format|
      if request.xhr?
        format.js { render :js => "kss.redirect('!_#{meet_up_path(@meet_up)}')"}
      elsif galapagos?
        format.html { redirect_to @meet_up }
      end
  end
  end
end
