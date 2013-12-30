class ConferencesController < ApplicationController
  authorize_resource :except => [:ks_cache_version]
  respond_to :html, :js
  include Kamishibai::ResponderMixin

  # GET /conferences
  # GET /conferences.json
  def index
    @conferences = Conference.all

    respond_with @conferences
  end

  # GET /conferences/1
  # GET /conferences/1.json
  def show
    @conference = Conference.find(params[:id])

    respond_with @conference
  end

  # GET /conferences/new
  # GET /conferences/new.json
  def new
    @conference = Conference.new

    respond_with @conference
  end

  # GET /conferences/1/edit
  def edit
    @conference = Conference.find(params[:id])

    respond_with @conference
  end

  # POST /conferences
  # POST /conferences.json
  def create
    @conference = Conference.new(params[:conference])

    if @conference.save
      flash[:notice] = 'Conference was successfully created.'
    end
    respond_with @conference
  end

  def ks_cache_version
    
  end

  # PUT /conferences/1
  # PUT /conferences/1.json
  def update
    @conference = Conference.find(params[:id])
    if @conference.update_attributes(params[:conference])
      flash[:notice] = 'Conference was successfully updated.'
    end

    respond_with @conference
  end

  # DELETE /conferences/1
  # DELETE /conferences/1.json
  def destroy
    @conference = Conference.find(params[:id])
    @conference.destroy

    respond_with @conference
  end
end
