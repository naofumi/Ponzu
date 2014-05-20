class GlobalMessagesController < ApplicationController
  authorize_resource
  respond_to :html, :js
  include Kamishibai::ResponderMixin

  set_kamishibai_expiry [:index] => 1 # Store in cache for 1 second

  # GET /global_messages
  # GET /global_messages.json
  def index
    @global_messages = GlobalMessage.in_conference(current_conference).
                       order("created_at DESC").
                       paginate(:per_page => 10, :page => params[:page])

    respond_with @global_messages
  end

  # GET /global_messages/1
  # GET /global_messages/1.json
  def show
    @global_message = GlobalMessage.in_conference(current_conference).find(params[:id])

    respond_with @global_messages
  end

  # GET /global_messages/new
  # GET /global_messages/new.json
  def new
    @global_message = GlobalMessage.new

    respond_with @global_messages
  end

  # GET /global_messages/1/edit
  def edit
    @global_message = GlobalMessage.in_conference(current_conference).find(params[:id])

    respond_with @global_messages
  end

  # POST /global_messages
  # POST /global_messages.json
  def create
    @global_message = GlobalMessage.new(params[:global_message])
    @global_message.conference_confirm = current_conference

    @global_message.save ? 
      flash[:notice] = 'Global message was successfully created.' :
      flash[:error] = 'Failed to create Global message.'

    respond_with @global_message
  end

  # PUT /global_messages/1
  # PUT /global_messages/1.json
  def update
    @global_message = GlobalMessage.in_conference(current_conference).find(params[:id])

    @global_message.update_attributes(params[:global_message]) ? 
      flash[:notice] = 'Global message was successfully updated.' :
      flash[:error] = 'Failed to update Global message.'
    
    respond_with @global_message
  end

  # DELETE /global_messages/1
  # DELETE /global_messages/1.json
  def destroy
    @global_message = GlobalMessage.in_conference(current_conference).find(params[:id])
    @global_message.destroy

    @global_message.destroyed? ?
      flash[:notice] = 'Global message was successfully deleted.' :
      flash[:error] = 'Failed to delete Global message.'
    
    respond_with @global_message
  end
end
