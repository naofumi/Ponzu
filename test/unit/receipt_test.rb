require 'test_helper'

class ReceiptTest < ActiveSupport::TestCase
  def setup
    @sender = users(:generic_user)
    @recipient = users(:generic_user_2)
  end

  test "should refer to conference" do
    message = @sender.send_message(:to => @recipient, :subject => "HOWDY", :body => "How are you?")
    r = message.receipts.first
    assert_equal @recipient.conference.database_tag, r.conference_tag
  end

  test "should raise error if sender and recipient belong to difference conference" do
    r = users(:user_from_different_conference)
    e = assert_raise ActiveRecord::RecordInvalid do
      message = @sender.send_message(:to => r, :subject => "HOWDY", :body => "How are you?")
    end
    assert_equal "Validation failed: receiver.conference_tag (another_conference) must match Receipt#conference_tag (generic_conference).",
                 e.message
  end
end
