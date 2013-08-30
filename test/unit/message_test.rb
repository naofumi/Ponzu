# encoding: utf-8
require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  def setup
    @sender = users(:generic_user)
    @recipient = users(:generic_user_2)
    @sender_2 = users(:generic_user_3)
    @presentation = presentations(:generic_presentation)
    @conference = conferences(:generic_conference)
  end

  test "message should implement #conference" do
    message = @sender.send_message(:to => @recipient, :subject => "HOWDY", :body => "How are you?")
    assert_equal message.conference, @conference
  end

  def test_simple_messaging
    @sender.send_message(:to => @recipient, :subject => "HOWDY", :body => "How are you?")
    assert_equal "HOWDY", @recipient.receipts.first.message.subject
    assert_equal "HOWDY", @sender.receipts.first.message.subject
    assert_equal "How are you?", @recipient.receipts.first.message.body
    assert_equal "How are you?", @sender.receipts.first.message.body
  end

  def test_simple_messaging_from_presentation
    @presentation.send_message(:to => @recipient, :subject => "from Presentation", :body => "I'm a presentation")
    assert_equal "from Presentation", @recipient.receipts.first.message.subject
    assert_equal "from Presentation", @presentation.receipts.first.message.subject
  end

  def test_receipts_by_type
    @sender.send_message(:to => @recipient, :subject => "HOWDY", :body => "How are you?")
    @presentation.send_message(:to => @recipient, :subject => "from Presentation", :body => "I'm a presentation")
    assert_equal 1, @recipient.receipts_from_type(Presentation).size
    assert_equal "from Presentation", @recipient.receipts_from_type(Presentation).first.message.subject
    assert_equal 1, @recipient.receipts_from_type(User).size
    assert_equal "HOWDY", @recipient.receipts_from_type(User).first.message.subject
  end

  def test_unread_receipts_by_type
    @sender.send_message(:to => @recipient, :subject => "HOWDY", :body => "How are you?")
    @sender.send_message(:to => @recipient, :subject => "HOWDY2", :body => "How are you?")
    @sender.send_message(:to => @recipient, :subject => "HOWDY3", :body => "How are you?")
    assert_equal 3, @recipient.receipts_from_type(User).unread.size
    assert_equal 0, @recipient.receipts_from_type(User).read.size
    @recipient.receipts.last.set_read
    assert_equal 2, @recipient.receipts_from_type(User).unread.size
    assert_equal 1, @recipient.receipts_from_type(User).read.size
  end

  def test_messages_to_or_from_type
    @sender.send_message(:to => @recipient, :subject => "HOWDY", :body => "How are you?")
    sleep 1 # To facilitate ordering
    @recipient.send_message(:to => @sender, :subject => "HOWDY TO YOU TOO", :body => "Fine, thank you.")
    assert_equal 2, @recipient.receipts_to_or_from_type(User).size
    assert_equal ["HOWDY TO YOU TOO", "HOWDY"], @recipient.receipts_to_or_from_type(User).map{|r| r.message.subject}
    assert_equal 2, @sender.receipts_to_or_from_type(User).size
    assert_equal ["HOWDY TO YOU TOO", "HOWDY"], @sender.receipts_to_or_from_type(User).map{|r| r.message.subject}
  end

  def test_messages_to_or_from_user
    @sender.send_message(:to => @recipient, :subject => "HOWDY", :body => "How are you?")
    @recipient.send_message(:to => @sender, :subject => "Re: HOWDY", :body => "fine thank you")
    @sender_2.send_message(:to => @recipient, :subject => "Hi", :body => "How are you?")
    assert_equal 3, @recipient.receipts_to_or_from_type(User).size
    assert_equal 2, @recipient.receipts_to_or_from(@sender).size
  end

  def test_messages_to_user
    @sender.send_message(:to => @recipient, :subject => "HOWDY", :body => "How are you?")
    @recipient.send_message(:to => @sender, :subject => "Re: HOWDY", :body => "fine thank you")
    @sender_2.send_message(:to => @recipient, :subject => "Hi", :body => "How are you?")
    assert_equal 1, @recipient.receipts_to_type(User).size
    assert_equal 1, @recipient.receipts_to(@sender).size
  end

  def test_messages_from_user
    @sender.send_message(:to => @recipient, :subject => "HOWDY", :body => "How are you?")
    @recipient.send_message(:to => @sender, :subject => "Re: HOWDY", :body => "fine thank you")
    @sender_2.send_message(:to => @recipient, :subject => "Hi", :body => "How are you?")
    assert_equal 1, @recipient.receipts_from(@sender).size
    assert_equal 0, @recipient.receipts_to(@sender_2).size
  end

  def test_email_should_be_sent
    @recipient.update_attributes! :email => "test@example.com", :password => "my_pass", :password_confirmation => "my_pass"
    @sender.send_message(:to => @recipient, :subject => "test_1234", 
                         :body => "test message content 123543", :mailer_method => :private_message)
    # Assume that the last delivery will be the one.
    email = ActionMailer::Base.deliveries.last
    assert_match email.subject, "Demo: Message from #{@sender.en_name}"
    assert_match email.encoded, /test message content 123543/    
  end

  # This should probably live in presentation_test.rb, but we put it in
  # here for the time being
  def test_email_should_be_sent_for_presentation_modified
    presentation = presentations(:generic_presentation)
    @recipient.update_attributes! :email => "test@example.com", :password => "my_pass", :password_confirmation => "my_pass"
    presentation.send_message(:to => [@recipient], :mailer_method => :presentation_modified)
    # Assume that the last delivery will be the one.
    email = ActionMailer::Base.deliveries.last
    assert_match email.subject, "Demo: Presentation #{presentation.number} modified"
    assert_match email.encoded, /Presentation #{presentation.number} was modified/    
  end

  # This should probably live in comment_test.rb, but we put it in
  # here for the time being
  def test_email_should_be_sent_for_comment_added
    comment = comments(:generic_comment)
    @recipient.update_attributes! :email => "test@example.com", :password => "my_pass", :password_confirmation => "my_pass"
    comment.send_message(:to => [@recipient], :mailer_method => :comment_added)
    # Assume that the last delivery will be the one.
    email = ActionMailer::Base.deliveries.last
    assert_match email.subject, "Demo: New comment on presentation #{comment.presentation.number}"
    assert_match email.encoded, /#{comment.text}/    
  end

  def test_email_should_be_sent_in_Japanese
    pending "Pending Japanese translation"
    # set locale to :ja
    # send message and assert
  end

  def test_no_email_sending_if_email_is_undefined_or_blank
    assert_difference "ActionMailer::Base.deliveries.size", 0 do
      @sender.send_message(:to => users(:user_without_email), :subject => "HOWDY", 
                           :body => "How are you?", :mailer_method => :private_message)
    end
    assert_difference "ActionMailer::Base.deliveries.size", 1 do
      @sender.send_message(:to => users(:generic_user), :subject => "HOWDY", 
                           :body => "How are you?", :mailer_method => :private_message)
    end
    # Assume that the last delivery will be the one.
    email = ActionMailer::Base.deliveries.last
    assert_match email.encoded, /How are you\?/
  end

  # Multi-conference
  test "sender and receipt conferences must match" do
    assert_raise ActiveRecord::RecordInvalid do
      @sender.send_message(:to => users(:user_from_different_conference_with_same_login), :subject => "HOWDY", 
                           :body => "How are you?", :mailer_method => :private_message)    
    end
  end
end
