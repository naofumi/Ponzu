class RegistrantsController < ApplicationController
  require 'ks_will_paginate_link_renderer'

  authorize_resource
  # GET /registrants
  # GET /registrants.json
  def index
    if params[:only_active]
      @registrants = Registrant.includes(:user).where('users.login IS NOT NULL')
    else      
      @registrants = Registrant.includes(:user)
    end

    if params[:from]
      @registrants = @registrants.where("registrants.id >= ?", params[:from])
    end

    if params[:grey]
      @registrants = @registrants.where("users.registrant_whitelist_status = ?", 0)
    end

    if params[:black]
      @registrants = @registrants.where("users.registrant_whitelist_status = ?", -1)
    end

    @registrants = @registrants.includes(:user).order('registrants.id').paginate(:per_page => 30, :page => params[:page])

    respond_to do |format|
      format.html { render } # index.html.erb
      format.json { render json: @registrants }
    end
  end

  # Whitelist the association between a User and a Registrant
  # via User#login
  def whitelist
    last_registrant = Registrant.find(params[:last_registrant_id])
    ok_registrants = Registrant.find(params[:registrant_ok])
    ng_registrants = params[:registrant_ng] ? Registrant.find(params[:registrant_ng]) : []
    ok_registrants.each do |r|
      u = r.user
      u.registrant_whitelist_status = :white
      u.save!
    end
    ng_registrants.each do |r|
      u = r.user
      u.registrant_whitelist_status = :black
      u.save!
    end
    next_registrant = Registrant.where("id > ?", last_registrant.id).order(:id).first
    redirect_to :action => 'index', :only_active => true, :from => next_registrant && next_registrant.id, :grey => true
  end

  # GET /registrants/1
  # GET /registrants/1.json
  def show
    @registrant = Registrant.find(params[:id])

    respond_to do |format|
      if request.xhr?
        format.html { render :layout => false} # show.html.erb
      else
        format.html {}
      end
      format.json { render json: @registrant }
    end
  end

  # GET /registrants/new
  # GET /registrants/new.json
  def new
    @registrant = Registrant.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @registrant }
    end
  end

  # GET /registrants/1/edit
  def edit
    @registrant = Registrant.find(params[:id])
  end

  # POST /registrants
  # POST /registrants.json
  def create
    @registrant = Registrant.new(params[:registrant])

    respond_to do |format|
      if @registrant.save
        format.html { redirect_to @registrant, notice: 'Registrant was successfully created.' }
        format.json { render json: @registrant, status: :created, location: @registrant }
      else
        format.html { render action: "new" }
        format.json { render json: @registrant.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /registrants/1
  # PUT /registrants/1.json
  def update
    @registrant = Registrant.find(params[:id])

    respond_to do |format|
      if @registrant.update_attributes(params[:registrant])
        format.html { redirect_to @registrant, notice: 'Registrant was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @registrant.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /registrants/1
  # DELETE /registrants/1.json
  def destroy
    @registrant = Registrant.find(params[:id])
    @registrant.destroy

    respond_to do |format|
      format.html { redirect_to registrants_url }
      format.json { head :no_content }
    end
  end

  def toggle_activation_whitelist
    @registrant = Registrant.find(params[:id])
    @registrant.user.toggle_registrant_whitelist_status
    @registrant.save!
    respond_to do |format|
      format.js { render :js => "var e = document.getElementById('registration_list_registrant_#{@registrant.id}');" +
                  "kss.removeClass(e, 'grey');kss.removeClass(e, 'white');kss.removeClass(e, 'black');" +
                  "kss.addClass(e, '#{@registrant.user.registrant_whitelist_status}')"
                }
      # format.html { render :partial => "registrant_info_row", :locals => {:registrant => @registrant} }
    end
  end
end
