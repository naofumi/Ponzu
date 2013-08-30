class RoomsController < ApplicationController
  authorize_resource
  respond_to :html, :js
  include Kamishibai::ResponderMixin

  set_kamishibai_expiry [:show] => 24 * 60 * 60
  
  before_filter do |c|
    @menu = :sessions
    # @expiry = 60 * 60 # seconds
  end

  # GET /rooms
  # GET /rooms.json
  def index
    @rooms = Room.in_conference(current_conference).order(:position).all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /rooms/1
  # GET /rooms/1.json
  def show
    @room = Room.in_conference(current_conference).find(params[:id])

    respond_with @room
  end

  # GET /rooms/new
  # GET /rooms/new.json
  def new
    @room = Room.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /rooms/1/edit
  def edit
    @room = Room.in_conference(current_conference).find(params[:id])
  end

  # POST /rooms
  # POST /rooms.json
  def create
    @room = Room.new(params[:room])
    @room.conference = current_conference

    respond_to do |format|
      if @room.save
        flash[:notice] = 'Room was successfully created.'
        format.html { render :edit }
      else
        format.html { render action: "new" }
      end
    end
  end

  # PUT /rooms/1
  # PUT /rooms/1.json
  def update
    @room = Room.in_conference(current_conference).find(params[:id])

    respond_to do |format|
      if @room.update_attributes(params[:room])
        format.html { 
          if request.xhr?
            render action: "edit"
          else
            redirect_to @room, notice: 'Room was successfully updated.' 
          end
        }
      else
        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /rooms/1
  # DELETE /rooms/1.json
  def destroy
    @room = Room.in_conference(current_conference).find(params[:id])
    @room.destroy

    respond_with @room
  end

  def move_up
    @room = Room.in_conference(current_conference).find params[:id]
    @room.move_higher
    @room.save!
    respond_to do |format|
      format.html { run_action 'index', {}, :xhr => true}
    end
  end

  def move_down
    @room = Room.in_conference(current_conference).find params[:id]
    @room.move_lower
    @room.save!
    respond_to do |format|
      format.html { run_action 'index', {}, :xhr => true}
    end
  end
end
