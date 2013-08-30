require 'test_helper'

class PrivateMessageTest < ActiveSupport::TestCase
  def setup
    @sender = users(:generic_user)
    @receiver = users(:generic_user_2)
    @receiver_2 = users(:generic_user_3)
  end

  def test_assign_attributes_in_initialize
    pm = PrivateMessage.new(:subject => "Test subject", 
                            :body => "Test body",
                            :to_id => @receiver.id,
                            :from => @sender)
    assert_equal ["Test subject", "Test body", [@receiver.id], @sender],
                  [pm.subject, pm.body, pm.to_id, pm.from]
  end

  def test_should_validate_presence_of_body
    pm = PrivateMessage.new(:subject => "Test subject", 
                            :body => "",
                            :to_id => @receiver.id,
                            :from => @sender)    
    refute pm.valid?
  end

  def test_should_validate_presence_of_to_id
    pm = PrivateMessage.new(:subject => "Test subject", 
                            :body => "Test body",
                            :to_id => nil,
                            :from => @sender)    
    refute pm.valid?
  end

  def test_should_validate_presence_of_from
    pm = PrivateMessage.new(:subject => "Test subject", 
                            :body => "Test body",
                            :to_id => @receiver.id,
                            :from => nil)    
    refute pm.valid?
  end

  def test_save_should_send_message
    pm = PrivateMessage.new(:to_id => @receiver.id,
                            :body => "Test body",
                            :from => @sender)
    assert_difference("Message.count", 1) do
      pm.save
    end
  end

  def test_save_should_create_receipts
    pm = PrivateMessage.new(:to_id => @receiver.id,
                            :body => "Test body",
                            :from => @sender)
    assert_difference("Receipt.count", 2) do
      pm.save
    end
  end

  def test_threads_should_combine_conversation
    send_1 = factory_pm from: @sender, to: @receiver
    reply_1 = factory_pm from: @receiver, to: @sender
    send_2 = factory_pm from: @sender, to: @receiver

    receipts = Receipt.threads_for_obj(@sender).all
    assert_equal 1, receipts.size
  end

  def test_threads_should_combine_conversation_but_be_different_by_correspondant
    send_1 = factory_pm from: @sender, to: @receiver
    reply_1 = factory_pm from: @receiver, to: @sender
    send_2 = factory_pm from: @sender, to: @receiver
    send_other = factory_pm from: @sender, to: @receiver_2

    receipts = Receipt.threads_for_obj(@sender).all
    assert_equal 2, receipts.size
  end

  def test_threads_should_ignore_unrelated_conversations
    send_1 = factory_pm from: @sender, to: @receiver
    reply_1 = factory_pm from: @receiver, to: @sender
    send_2 = factory_pm from: @sender, to: @receiver
    send_other = factory_pm from: @sender, to: @receiver_2
    unrelated = factory_pm from: @receiver, to: @receiver_2

    receipts = Receipt.threads_for_obj(@sender).all
    assert_equal 2, receipts.size
    threads = receipts.map{|r| [r.receiver_id, r.message_count]}
    assert_include threads, [@receiver_2.id, 1]
    assert_include threads, [@receiver.id, 3]
  end

  def test_get_threads_as_thread_objects
    send_1 = factory_pm       from: @sender,    to: @receiver
    reply_1 = factory_pm      from: @receiver,  to: @sender
    send_2 = factory_pm       from: @sender,    to: @receiver
    send_other = factory_pm   from: @sender,    to: @receiver_2
    unrelated = factory_pm    from: @receiver,  to: @receiver_2

    threads = PrivateMessage.threads(@sender)
    assert_equal 2, threads.size
    assert_include threads.map{|t| t.partner}, @receiver
    assert_equal 3, threads.detect{|t| t.partner == @receiver}.message_count
  end

  def test_read_status_in_threads
    send_1 = factory_pm       from: @sender,    to: @receiver
    reply_1 = factory_pm      from: @receiver,  to: @sender
    send_2 = factory_pm       from: @sender,    to: @receiver

    assert_difference("PrivateMessage.threads(@sender).first.unread_count", -1) do
      the_receipt = @sender.receipts_from(@receiver).first
      the_receipt.set_read
    end
  end

  def test_private_message_threads_should_ignore_non_private_messages
    private_message_threads_count = PrivateMessage.threads(@sender).count
    all_threads_count = @sender.threads.count
    # message from Presentation
    @presentation = presentations(:generic_presentation)
    @presentation.send_message(:to => @sender, :subject => "presentation updated")

    assert_equal private_message_threads_count, PrivateMessage.threads(@sender).count
    assert_equal all_threads_count + 1, @sender.threads.count
  end

  def factory_pm(options)
    from, to = options[:from], options[:to]
    PrivateMessage.create(to_id: to.id, from: from, body: "Test body")
  end
end
