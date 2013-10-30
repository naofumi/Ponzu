require 'test_helper'

class PrivateMessagesControllerTest < ActionController::TestCase
  setup :activate_authlogic

  def setup
    @request.user_agent = mountain_lion_safari_ua
    @request.host = "generic-conference.ponzu.local"

    @sender = users(:generic_user)
    @receiver = users(:generic_user_2)
    @receiver_2 = users(:generic_user_3)

    @send_1 = PrivateMessage.create(:to_id => @receiver.id,
                                :body => "Test body",
                                :from => @sender)
    reply_1 = PrivateMessage.create(:to_id => @sender.id,
                                :body => "Test body",
                                :from => @receiver)
    send_2 = PrivateMessage.create(:to_id => @sender.id,
                                :body => "Test body",
                                :from => @receiver)
    send_other = PrivateMessage.create(:to_id => @receiver_2.id,
                                :body => "Test body",
                                :from => @sender)
    unrelated = PrivateMessage.create(:to_id => @receiver_2.id,
                                :body => "Test body",
                                :from => @receiver)
    @private_message_on_other_conference = PrivateMessage.create(:to_id => users(:user_from_different_conference).id,
                                                                 :body => "Test body",
                                                                 :from => users(:user_from_different_conference_with_same_login))
  end

  def test_get_new_private_message
    login_as_user
    ks_ajax :get, :new, :to_id => @receiver.id
    assert_response :success
  end

  def test_create_new_private_message
    login_as_user
    assert_difference("Message.count") do
      ks_ajax :post, :create,
        private_message: {to_id: @receiver.id,
                          body: "New message"}
    end
    assert_redirected_to conversation_private_messages_path(:with => assigns(:private_message).to)
  end

  def test_get_index
    login_as_admin
    ks_ajax :get, :index
    assert_response :success
    assert_not_include assigns(:private_messages), @private_message_on_other_conference
    assert_ponzu_frame
    assert_template :index
  end

  def test_get_threads
    login_as_user
    ks_ajax :get, :threads
    assert_response :success
    assert_ponzu_frame
  end

  def test_get_conversation
    login_as_user
    ks_ajax :get, :conversation, :with => @receiver
    assert_response :success
    assert_ponzu_frame
  end

end
