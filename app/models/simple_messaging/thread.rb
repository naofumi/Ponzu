module SimpleMessaging
  # A private message thread.
  #
  # Thread objects are created using 
  # SimpleMessaging.threads and conveniently
  # provide infomation about each thread.
  #
  # Attributes;
  #
  # #partner::
  #   The User whom we are talking to in this thread.
  # message_count::
  #   The number of messages in this thread.
  # newest_message_at::
  #   The time the newest message in this thread was created.
  # newest_message::
  #   The newest message. Useful if you want to show an excerpt
  #   of the newest message in a list of threads.
  # read_status::
  #   A string telling us which messages have been read. Use
  #   #unread_count to process this string and get the number of
  #   unread messages.
  # receipt_ids::
  #   String telling us the ids of the receipts in each thread.

  class Thread
    attr_reader :partner, :message_count, :newest_message_at, :read_status, 
                :newest_message, :receipt_ids

    # Used in SimpleMessaging#threads. Generates an array of Thread objects
    # from a Receipt.threads_for_obj scope.
    def self.all_from_receipt_scope(receipt_scope)      
      receipt_scope.inject([]) do |memo, r|
        # TODO: Batch create partners and newest_messages to reduce SQL queries
        partner = r.receiver_type.constantize.send(:find, r.receiver_id)
        newest_message = Message.order("messages.created_at DESC").find(r.message_ids.split(',')).first
        # newest_message_at is retrieved as a #select attribute, hence
        # ActiveRecord hasn't coerced it as a datetime.
        thr = Thread.new(partner, r.message_count, r.newest_message_at.in_time_zone, 
                         r.read_status, newest_message, r.receipt_ids)
        memo << thr
      end      
    end

    # Gets the unread count of the current Thread
    def unread_count
      read_status.split(',').select{|read| read == '0'}.size
    end

    # Gets the unread Receipt object IDs in the current Thread.
    def unread_receipt_ids
      read_statuses = read_status.split(',')
      receipt_ids = @receipt_ids.split(',')
      read_statuses.zip(receipt_ids).map{|status, id| status == '0' ? id.to_i : nil}.compact
    end

    # Thread objects are created in #all_from_receipt_scope so this should never be necessary.
    def initialize(partner, message_count, newest_message_at, read_status, newest_message, receipt_ids)
      @partner, @message_count, @newest_message_at, @read_status, @newest_message, @receipt_ids = 
        partner, message_count, newest_message_at, read_status, newest_message, receipt_ids
    end
  end
end