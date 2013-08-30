# This handles the messages and notifications that we use throughout the system.
# Compared to Mailboxer, it is much simpler. Moreover, it provides methods to
# extract messages by conversation participants, which was difficult with Mailboxer.
#
# == How to use
#
# Include this module into an Class that you would like to use as a message sender
# or message receiver. For example in Ponzu, we usually include it into User,
# Presentation, Comment, Like, MeetUp, MeetUpComment objects.
#
#   def User
#     include SimpleMessaging
#   end
#
# == Major Objects and terminology
#
# <code>Message</code>::
#   This object contains the message itself (the subject and the body).
#   It also contains the +sender+ which can be any object. Importantly, it does not
#   contain any information about whom the message was sent to.
#
# <code>Receipt</code>::
#   This object contains the information on the recepient side. When
#   we send a message, we create a Receipt object for each recipient.
#   The Receipt object contains the +receiver+ object and the +message+ object
#   The +receiver+ is polymorphic and accepts any kind of object.
#   It also has a +read+ attribute to track which messages have been read
#   by the recipient.
#
# == Interface for getting Receipts and Messages
#
# The following methods (_from methods) are available for getting Receipt objects.
# By this we mean the Receipts that were received by the current object.
# Receipts are returned in descending order of +created_at+.
# (for other objects, look at the API below)
#
# <code>receipts</code>::
#   Returns all Receipts.
#
# <code>receipts_from_obj(obj)</code>:: 
#   Returns the Receipts that were sent from +obj+.
#
# <code>receipts_from_type(type)</code>:: 
#   Returns the Receipts that were sent from class +type+.
#
# SimpleMessaging generates Receipts when an object sends out a message.
# This is similar to <i>sent mails</i> in a regular email client. To 
# get these Receipts together withe the Receipts that were received,
# SimpleMessaging provides +to_or_from+ methods.
#
# <code>receipts_to_or_from(obj)</code>:: 
#   Returns the Receipts that were sent from +obj+
#   to the current object, or conversely, sent from the current object to +obj+. This is
#   useful for generating a iMessage or Twitter Direct messages like interface.
#
# <code>send_messages</code>::
#   Returns the messages that were sent from this object.
#
# == Interface for sending Messages
#
# Send messages with the #send_message method.
#
#   @sender.send_message(:to => @recipient, :subject => "HOWDY", 
#                        :mailer_method => :private_message)
#
# <tt>:to</tt>::
#   The reciever object for this message. It can be a single object or an Array of objects.
#   Will also receive an email notification if it responds to +email+ with a non-blank string.
#
# <tt>:mailer_method</tt>::
#   Symbol to a mail method on the MessageMailer class. If
#   this option is specified, a notification message will be sent to all reciever objects
#   which respond to +email+ with a non-blank value. This mail method will be used
#   to compose the email.
#
# === Comparison with Mailboxer
#
# A very important difference compared to Mailboxer is that you can specify your own
# mailer_method. Mailboxer had two fixed mailer_methods that you could not select
# when you created a message. 
#
# With SimpleMessage, different mailer_methods can interpret the original message more
# flexibly, allowing you to generate i18n mails and well designed mails.
#
# For example, if we were sending a User a new_comment_added message, we would not
# send a +subject+ or +body+ because the sender of the message would be a Comment
# object, and that Comment object would have enough information within it.
#
# Because we can use a specialized mailer_method for new_comment_added, we can 
# customize it so that extracts information from the Comment object associated with the
# Message, instead of using the +subject+ and +body+ verbatim. We could also use i18n
# to change the language of the email.
#
# On the other hand, when we send an email as a notification for a new private_message,
# we can specify a different mailer_method that will use the +subject+ and +body+ fields
# verbatim.
# 
# == Sending notifications with SimpleMessaging
#
# Here we show an example where a Presentation object will notify the people
# who "like" it when the presentation is changed.
#
# /app/models/presentation.rb
#    class Presentation < ActiveRecord::Base
#      after_save   :notify_likers_of_changes 
#      private
# 
#      # Notify users who like this Presentation when something has changed.
#      def notify_likers_of_changes # :doc:
#        if !likes.empty?
#          likers = likes.map{|l| l.user}
#          send_message(:to => likers, :mailer_method => :presentation_modified)
#        end
#      end
#    end
#
# /app/mailers/message_mailer.rb
#    class MessageMailer < ActionMailer::Base
#      helper :kamishibai_path
#      default from: "from@example.com"
#
#      def presentation_modified(option)
#        @bootloader_path = default_bootloader_path
#        @to, @subject, @body, @obj = option[:to], option[:subject], option[:body], option[:obj]
#        mail(:to => @to.map{|u| u.email}, 
#             :subject => "Presentation #{@obj.number} modified")
#      end
#
#      private
#
#      def default_bootloader_path
#        Rails.configuration.message_mailer_bootstrap
#      end
#    end
#
#
# /app/views/message_mailer/presentation_modified.html.haml
#    !!! 5
#    %head
#      %meta(content="text/html; charset=UTF-8" http-equiv="Content-Type")/
#      %body
#        Presentation #{@obj.number} was modified.
#
#        Checkout #{ksp(@obj, :bootloader_path => @bootloader_path)} for details.
#
# In the Presentation Class, we use the +after_save+ hook and call +#notify_likers_of_changes+.
# This then sends the message with +send_message+. Note that we only provide the +:to+
# and the +:mailer_method+ options. We don't set the +:subject+ or +:body+ because
# that information is contained in the +sender+ of the Message object (in this case, the 
# Presentation object itself).
#
# In the MessageMailer Class, we send the email by calling +#presentation_modified+ as 
# specified in the +#send_message+ arugment. +#presentation_modified+ sets the +:subject+
# and +:to+ arguments.
#
# In the view template +/app/views/message_mailer/presentation_modified.html.haml+, we
# generate the body of the email message using the Presentation object which is now referenced by
# the @obj instance variable.
#
# Note that we have supplied the +:bootloader_path+ option to KamishibaiPathHelper.ksp so that we can generate
# full URLs. Also note that we have enabled +kamishibai_path_helper+ methods by using
# the +helper+ declaration in MessageMailer.
#
# == What to put into the +subject+ and +body+ of the Message
#
# Although the API allows us to set +subject+ and +body+ for each message, this
# is often unnecessary. This is because the sender object often contains enough
# information for the receiver.
#
# For example, if we were sending a notification that a new comment had been 
# added, then it would be sufficient if the User (Author) could get the Comment
# object through the +#sender+ attribute of the Message. We would need to
# create an email message if email notifications are necessary, but composing
# the subject and body is a +view+ matter, and is best left to the MessageMailer.
#
# Hence in many, if not most cases, the +subject+ and +body+ will not need to
# be set. For private_messages however, the Message object itself contains
# the meat of the information. The +sender+ (User) does not contain the message
# contents, etc. In these cases, we need the +subject+ and +body.
#
# In Mailboxer, I think we were required to provide a +subject+ and/or +body+
# which was quite annoying for me.
#
# The +subject+ and +body+ do not necessarily need to be text information. For
# example, if a notification could be represented as a code, for example,
# a "please_update_billing_information" kind of notification, then we should
# use the +subject+ as a symbol. For example, by setting the +subject+ as
# ":please_update_billing_information", we could use an appropriate template
# when rendering views or sending emails. By not keeping the actual text in
# each Message object, we can handle i18n, etc. better.
#
# == Suggestions for implementing SimpleMessaging in various messaging scenarios
#
# === Email-like messages or Twitter direct-message like system
#
# The characteristics of Email messages are as follows;
#
# 1.  There is not inherent conversation thread. Email clients can group
#     messages into threads, but the messages themselves have no provision
#     for threads. Hence email clients make intelligent guesses based on
#     conversation members and/or title.
# 2.  There is not inherent attachment mechanism. Attachments are actually
#     encoded into the message body as text, which the client encodes and 
#     decodes automatically.
#
# Therefore, all the information that you really need is a body and a subject.
# (the subject could be embedded into the body so it is not absolutely necessary).
#
# In this case, you would simply include SimpleMessaging into your User objects,
# and then your User objects could message each other.
#
# However, it is often better to wrap SimpleMessage with a object like PrivateMessage.
# By using an ActiveRecord wrapper, you could easily provide validation and better
# integration with ActionPack.
#
# This is how we do it in Ponzu. Below is an example of the PrivateMessage object.
#
#     class PrivateMessage
#    
#       include ActiveModel::Conversion
#       include ActiveModel::Validations
#       validates_presence_of :body, :to_id, :from
#       include ActiveModel::MassAssignmentSecurity
#       attr_accessor :subject, :body, :to_id, :from
#       attr_reader :to
#       attr_accessible :subject, :body, :to_id, :from
#    
#       def initialize(values = {})
#         assign_attributes values
#       end
#      
#       # Copied from rdoc in ActiveModel::MassAssignmentSecurity::ClassMethods
#       def assign_attributes(values, options = {})
#         sanitize_for_mass_assignment(values, options[:as]).each do |k, v|
#           send("#{k}=", v)
#         end
#       end
#    
#       def to_id=(id)
#         @to_id = id.to_i unless id.blank?
#       end
#    
#       def to
#         @to ||= User.find(to_id)
#       end
#    
#       def save
#         if valid?
#           from.send_message(:to => to,
#                             :subject => subject,
#                             :body => body,
#                             :mailer_method => :private_message)
#           true
#         else
#           false
#         end
#       end
#    
#       def self.create(*args)
#         self.new(*args).save
#       end
#      
#       def persisted?
#         false
#       end
#    
#       def self.threads(user)
#         user.threads(Receipt.from_type('User'))
#       end
#    
#     end
#
# The methods #initialize, #assign_attributes, #to_id= and #to implement 
# mass-assignment and make it easy to create a new message from 
# ActionController.params.
#
# The #save and PrivateMessage#create methods run the validations
# and send the message if valid. Otherwise, errors will be added to 
# the object.
#
# We also have a PrivateMessage#threads method that delegates to the
# SimpleMessaging#thread method. This #thread is an implementation of email-client
# like threading behavior. It is however much simpler. It simply groups
# together messages by the other conversation participant.
# As such, the #threads method only works when a PrivateMessage is
# between two Users. If you have messages with more than two participants,
# then the results become very different from what you would normally
# expect.
#
# If you want to implement something like Twitter's direct messages,
# then the #threads method works almost exactly the same way.
#
# === Threaded discussions
#
# If you want to implement threaded discussions, then the Message
# object, only having a +subject+ and +body+, will not be sufficient.
#
# In these cases, you should implement the discussion Posts as 
# seperate objects, and then include SimpleMessage in the Post class.
#
# In this case, the Message will not contain any +subject+ or +body+
# information, but will act as a simply activity notification which
# hold a reference to the Post that sent them.
#
# Another way of looking at it is that if you want threaded-messages,
# then create objects that implement the threads and use SimpleMessage
# as a notification system only.
#
# === Conversation threads from a UI perspective
#
# One of the reasons why we don't have inherent threads in SimpleMessages
# is, in addition to the implementation complexity, because notifications
# to threads are rather tricky from a UI perspective.
#
# In email clients, you can send a reply to all members participating in 
# a discussion, or you can send to only one person. You are in full
# control over who receives your message. This is because email messages
# are not bound to discussion threads.
#
# On the other hand, if you are posting to a forum, then you are 100% aware
# that anybody can read that post, whether or not they are notified.
#
# Things get murky if you implement a threaded discussion in an email-like interface.
# Basically, you shouldn't do this.
#
# That's why we don't have inherent threads. If you want to have threads,
# then make you system forum-like and implement threads in the Post objects
# and explicitly show those threads in the UI. Don't use an email-like interface.
#
# We want the SimpleMessage system to be intuitive in email-like scenarios,
# and that's why we don't have inherent threads.
module SimpleMessaging
  def self.included(base)
    base.extend ClassMethods
    
    base.has_many    :sent_messages, :as => :sender, :class_name => "Message", :order => "messages.created_at DESC"
    base.has_many    :receipts, :as => :receiver, :order => "receipts.created_at DESC", :dependent => :destroy
    class << base
      @@silence = false
    end
  end

  # Override this method and return true
  # if you want to turn off all message sending
  # for testing purposes.
  def SimpleMessaging.silence_all
    false
  end

  module ClassMethods
    # Set silence to true if you want to silence SimpleMessage from
    # sending messages for this Class. Useful during testing or batch updating.
    def silence=(boolean)
      @@silence = boolean
    end
    
    def silence
      unless SimpleMessaging.silence_all
        defined?(@@silence) ? @@silence : false
      else
        true
      end
    end
  end

  def send_message(options)
    if self.class.silence
      logger.info "SILENCE SimpleMessaging.send_message"
      return
    end
    recipient_users = options[:to]
    recipient_users = [recipient_users] unless recipient_users.kind_of? Array
    subject = options[:subject]
    body = options[:body]
    mailer_method = options[:mailer_method]
    
    message = create_message_and_receipts(:subject => subject, :body => body, 
                                          :receivers => recipient_users)

    send_email(:subject => subject, :body => body, 
               :receivers => recipient_users, :mailer_method => mailer_method)
    return message
  end



  def receipts_from_type(type)
    receipts.from_type(type)
    # receipts.includes(:message).where("messages.sender_type" => type.to_s)
  end

  def receipts_from(obj)
    receipts.includes(:message).from_obj(obj)
  end

  # All the Receipts that make up the conversation
  # between +self+ and object of +type+
  def receipts_to_or_from_type(type)
    receipts.includes(:message).to_or_from_type(type)
  end

  # All the Receipts that make up the conversation
  # between +self+ and +obj+.
  def receipts_to_or_from(obj)
    receipts.includes(:message).to_or_from_obj(obj)
  end

  # All the sent_messages Receipts addressed to +obj+
  def receipts_to(obj)
    receipts_to_or_from(obj).sent_messages_receipts
  end

  # All the sent_messages Receipts addressed to object of +type+
  def receipts_to_type(type)
    receipts_to_or_from_type(type).sent_messages_receipts
  end

  # All the sent_messages Receipts
  def receipts_sent
    receipts.sent_messages_receipts
  end

  # All the threads which include a message that was
  # received by or sent from the current object.
  #
  # Grouped by conversation partner.
  #
  # Returns an array of SimpleMessaging::Thread objects.
  #
  # Works well for Twitter direct-message like interfaces,
  # but will return unexpected results if conversations
  # can include more than one participant.
  def threads(additional_recipt_scope = {})
    # receipt_scope = Receipt.threads_for_obj(self)
    # receipt_scope = if additional_recipt_scope
    #   additional_recipt_scope.call(Receipt.threads_for_obj(self))
    # else
    Receipt.with_scope(:find => additional_recipt_scope) do
      SimpleMessaging::Thread.all_from_receipt_scope Receipt.threads_for_obj(self)
    end
  end

  private

  # Creates Message and Receipt objects to fulfill #send_message.
  # Importantly, we create a Receipt for self. This becomes a
  # sent_message receipt.
  #
  # Returns the created message
  def create_message_and_receipts(options) #:doc:
    subject, body, receivers = options[:subject], options[:body], options[:receivers]
    message = nil # Return nil on fail
    Message.transaction do
      message = sent_messages.create!(:subject => subject, :body => body)
      receipts.create!(:message_id => message.id, :read => true) # sent_messages receipt for self
      receivers.each{|r| r && r.receipts.create!(:message_id => message.id)}
    end
    return message
  end

  def send_email(options)
    subject, body, receivers, mailer_method = 
             options[:subject], options[:body], options[:receivers], options[:mailer_method]
    if mailer_method
      mailable_receivers = receivers.select{|r| r.respond_to?(:email) && !r.email.blank?}
      if !mailable_receivers.empty?
        MessageMailer.send(mailer_method,
                           :to => mailable_receivers, 
                           :subject => subject, 
                           :body => body,
                           :obj => self).deliver
      end
    end
  end
end