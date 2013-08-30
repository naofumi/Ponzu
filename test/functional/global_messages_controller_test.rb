require 'test_helper'

class GlobalMessagesControllerTest < ActionController::TestCase
  setup :activate_authlogic

  setup do
    @global_message = global_messages(:generic_global_message)
    @request.user_agent = mountain_lion_safari_ua
    @request.host = "generic-conference.ponzu.local"
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:global_messages)
    assert_not_includes assigns(:global_messages), global_messages(:global_message_for_other_conference)
  end

  # Multiple conference test
  test "index should not contain other conference" do
    get :index
    assert_includes assigns(:global_messages), @global_message
    assert_not_includes assigns(:global_messages), global_messages(:global_message_for_other_conference)
  end

  test "should get new" do
    login_as_admin
    get :new
    assert_response :success
  end

  test "should create global_message" do
    login_as_admin
    assert_difference('GlobalMessage.count') do
      ks_ajax :post, :create, global_message: { en_text: @global_message.en_text,
                                      jp_text: @global_message.jp_text }
    end
    # Multiple conference test
    assert_equal conferences(:generic_conference), assigns(:global_message).conference

    assert_redirected_to global_message_path(assigns(:global_message))
  end

  test "should show global_message" do
    get :show, id: @global_message
    assert_response :success
  end

  # Multiple conference test
  test "should fail to show global_message for different conference" do
    assert_raise ActiveRecord::RecordNotFound do
      get :show, id: global_messages(:global_message_for_other_conference)
    end
  end

  test "should get edit" do
    login_as_admin
    get :edit, id: @global_message
    assert_response :success
  end

  test "should update global_message" do
    login_as_admin
    ks_ajax :put, :update, id: @global_message, global_message: { en_text: @global_message.en_text,
                                                        jp_text: @global_message.jp_text }
    assert_redirected_to global_message_path(assigns(:global_message))
  end

  # Multiple conference test
  test "cannot alter conference_id attribute via mass assignment" do
    login_as_admin
    assert_raise ActiveModel::MassAssignmentSecurity::Error do
      ks_ajax :put, :update, id: @global_message, 
              global_message: { en_text: @global_message.en_text,
                                jp_text: @global_message.jp_text,
                                conference_id: conferences(:another_conference) }
    end
  end

  test "should destroy global_message" do
    login_as_admin
    assert_difference('GlobalMessage.count', -1) do
      ks_ajax :delete, :destroy, id: @global_message
    end

    assert_redirected_to global_messages_path
  end

  # Multiple conference test
  test "cannot destory global_message from other conference" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :delete, :destroy, id: global_messages(:global_message_for_other_conference)
    end
  end
end
