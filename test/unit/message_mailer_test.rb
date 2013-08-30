require 'test_helper'

# Test the MessageMailer. 
# Also test SimpleMessage
class MessageMailerTest < ActionMailer::TestCase
	tests MessageMailer

	def setup
		@receivers = [users(:generic_user), 
			           users(:generic_user_3), 
			           users(:user_without_email)]
		@sender = users(:generic_user_2)
		# The confernence object is set to the first user
		@conference = users(:generic_user).conference

	end

	test "should send private message" do
		email = MessageMailer.private_message to: @receivers,
		     																	subject: "Test Message",
		     																	body: "Test body",
		     																	obj: @sender
		email.deliver
		assert !ActionMailer::Base.deliveries.empty?
		# sender address has the confernce tag
		assert_equal ["generic_conference-no-reply@castle104.com"], email.from
		# user_without_email is not included
    assert_equal [users(:generic_user).email, users(:generic_user_3).email], email.to
    # Subject is created from i18n entry
    assert_equal 'Demo: Message from Jiro Bunsei', email.subject
    assert_email_part_of_type email, 'text/plain',
                              "You have received the following private message."
    assert_email_part_of_type email, 'text/html',
                              "<h3>\nYou have received the following private message.\n</h3>"
	end

	test "should send all emails to addresses set in Conference#send_all_emails_to" do
		receivers = users(:generic_user)
		sender = users(:generic_user_2)
		@conference.update_attributes(:send_all_emails_to => "admin@conf.com admin2@conf.com")
		email = MessageMailer.private_message to: receivers,
		     																	subject: "Test Message",
		     																	body: "Test body",
		     																	obj: sender
		email.deliver
		# user_without_email is not included
    assert_equal ["admin@conf.com", "admin2@conf.com"], email.to
	end
end
