# This class has a lot of ActiveRecord scopes.
# 
# Note that users of this library should generally not
# use these scopes directly. Instead, use the methods provided
# in the SimpleMessaging module.
class Receipt < ActiveRecord::Base
  attr_accessible :message_id, :read, :receiver_id, :receiver_type
  belongs_to  :message, :inverse_of => :receipts
  belongs_to  :receiver, :polymorphic => true
  validates_presence_of :message_id, :receiver_id, :receiver_type

  def set_read
    update_attribute(:read, true)
  end

  def set_unread
    update_attribute(:read, false)
  end

  scope :read, where(:read => true)
  scope :unread, where(:read => false)

  include ConferenceRefer
  validates_conference_identity :receiver, :message
  infer_conference_from :receiver, :message

  ##
  # :singleton-method:
  # Receipts are created to each recipient of a message AND the sender.
  # The following scopes test whether this Receipt was generated for the sender or not.
  # Receipts created for the sender are like your "sent messages" mail tray.
  scope :received_messages_receipts, 
    joins(:message).
    where("messages.sender_id <> receipts.receiver_id OR messages.sender_type <> receipts.receiver_type")    

  scope :sent_messages_receipts,
    joins(:message).
    where("messages.sender_id = receipts.receiver_id AND messages.sender_type = receipts.receiver_type")    

  ##
  # :singleton-method:
  # These drill down based on the message sender.
  scope :from_type, lambda {|type|
    joins(:message).where("messages.sender_type" => type.to_s)
  }
  ##
  # :singleton-method:
  # These drill down based on the message sender.
  scope :from_obj, lambda {|obj|
    from_type(obj.class.to_s).where("messages.sender_id = ?", obj.id)
  }

  ##
  # :singleton-method:
  # These scopes finds Receipts that are either "sent messages" or "received messages"
  # and where either sent to or received from a specific object.
  #
  # This scope is essential for generating the conversation view similar to iMessage 
  # where you view a conversation between two people.
  #
  # With a receipt-based system, calculating the Tos is difficult because there are many
  # (calculating the Froms is simple because each Message can have only one From).
  # We need a join to connect the Messages to the Tos. Furthermore, we have to connect
  # the Receipts to the Messages with another join.
  #
  # The idea is to self join two Receipts via their common message, thus generating
  # a join with all combinations of receivers per message. We then restrict each receiver
  # in the where clause, using the 'receipts' table to restrict the returned Receipts 
  # (for example, the Receipts owned by a certain User object) and
  # the 'r_2' table to restrict via the other_recipients.
  #
  # The resulting query treats the receipts table and the other_receipts table 
  # symetrically. To distinguish between sent and received messages, use received_messages_receipts
  # or sent_messages_receipts.
  #
  # Note that the Receipts that #to_or_from_obj returns are the receipts that belong
  # to the other side of the conversation. The Receipts that are owned by obj
  # are being used in the join to find the relevant Messages.
  scope :to_or_from_obj, lambda {|obj|
    join_other_receipts.
    where("other_receipts.receiver_id = ? AND other_receipts.receiver_type = ?", 
          obj.id, obj.class.model_name.to_s)
  }
  scope :to_or_from_type, lambda {|type|
    join_other_receipts.
    where("other_receipts.receiver_type = ?", type.to_s)
  }
  scope :join_other_receipts,     
    joins(:message).
    joins("JOIN receipts AS other_receipts ON other_receipts.message_id = messages.id " + 
          " AND other_receipts.receiver_id <> receipts.receiver_id")

  ##
  # :singleton-method:
  # Useful when getting a list of conversation threads that an object
  # is participating in.
  #
  #   Receipt.threads_for_obj(obj)
  #
  # This returns a array of objects with the following attributes (we use SELECT)
  #
  # receiver_id, receiver_type:: Describes who the user is talking to in this thread.
  #
  # message_count:: The number of messages in this thread.
  #
  # message_ids:: String telling us the ids of the receipts in each thread.
  #
  # read_status:: 
  #   String telling us which messages were read. "0,1,1" would mean that the
  #   newest message has not been read, but the other have been read.
  #
  # receipt_ids::
  #   String telling us the ids of the receipts in each thread.
  #
  # The threads are sorted by newest_message_at in descending order.
  #
  # To limit the threads to PrivateMessages (messages sent by a User object to a
  # User object), add a from_type(User) to the scope.
  #
  #     Receipt.threads_for_obj.from_type(User)
  scope :threads_for_obj, lambda {|obj|
    select("receipts.receiver_id AS receiver_id, receipts.receiver_type AS receiver_type, " + 
           # "receipts.message_id AS newest_message_id, " +
           "COUNT(*) AS message_count, MAX(messages.created_at) AS newest_message_at, " +
           "GROUP_CONCAT(other_receipts.read) AS read_status, " +
           "GROUP_CONCAT(messages.id) AS message_ids, " +
           "GROUP_CONCAT(other_receipts.id) AS receipt_ids").
      to_or_from_obj(obj).order("newest_message_at DESC").group("receipts.receiver_id")
  }

end
