# encoding: UTF-8

class PrivateMessagesController < ApplicationController
  authorize_resource
  respond_to :html, :js
  include Kamishibai::ResponderMixin
  include PrivateMessageHelpers::Helpers

  set_kamishibai_expiry [:threads, :conversation] => 60


  def new
    @private_message = PrivateMessage.new(:to_id => params[:to_id],
                                          :subject => "private message")
  end
  
  # POST /private_message/
  def create
    @private_message = PrivateMessage.new(params[:private_message].
                                          merge(:from => current_user))

    if @private_message.save
      flash[:notice] = "Successfully sent Private Message"
    else
      flash[:error] = "Failed to send Private Message"
    end

    respond_with @private_message, 
      :location => conversation_private_messages_path(:with => @private_message.to.first)
  end
  
  def index
    # We can't use a fancy named_scope because :sender is
    # a polymorphic association, and we can't simply JOIN it.
    # Here, we directly write down the SQL.
    @private_messages = Message.where(:sender_type => 'User').
                                joins('INNER JOIN users on users.id = messages.sender_id').
                                where('users.conference_id = ?', current_conference).
                                paginate(page: params[:page], per_page: 50)
    respond_with @private_messages
  end
  
  def threads
    @threads = PrivateMessage.threads(current_user)

    respond_with @threads
  end

  # GET /private_messages/conversation?with=124
  def conversation
    @with = User.in_conference(current_conference).find(params[:with])
    @receipts = current_user.receipts_to_or_from(@with).paginate(:per_page => 30, :page => params[:page])
    # The object for the new private message entry box that we display.
    # The rest of the private messages are in @receipts
    @private_message = PrivateMessage.new(:to_id => @with.id, :subject => "private message")
    # If it is a non-galapagos device, then we use Ajax to send a request to
    # Receipts#mark_read to update the read status. However, we can't do this
    # for galapagos devices. Instead, we set the read status here.
    if galapagos?
      set_read_status_for_receipts
    end
  end

  # Deprecated and probably not working
  def destroy
    @private_message = PrivateMessage.find(params[:id])
    @private_message.destroy
    if @private_message.destoryed?
      flash[:notice] = "Private Message was successfully destroyed."
    else
      flash[:error] = "Failed to delete private message."
    end
    respond_with @private_message
  end
end
