require 'test_helper'

class MeetUpCommentsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  setup do
    @meet_up_comment = meet_up_comments(:generic_meet_up_comment)
    @request.user_agent = mountain_lion_safari_ua
    @request.host = "generic-conference.ponzu.local"
  end

  test "should get index" do
    login_as_admin
    ks_ajax :get, :index
    assert_response :success
    assert_not_nil assigns(:meet_up_comments)
    assert_ponzu_frame
  end

  # Multi conference support
  test "should not get index for other conferences" do
    login_as_admin
    ks_ajax :get, :index
    assert_include assigns(:meet_up_comments), meet_up_comments(:generic_meet_up_comment)
    assert_not_include assigns(:meet_up_comments), meet_up_comments(:meet_up_comment_for_other_conference)
  end

  test "should get new" do
    login_as_admin
    ks_ajax :get, :new
    assert_response :success
    assert_ponzu_frame
  end

  test "should create meet_up_comment" do
    login_as_user
    assert_difference('MeetUpComment.count') do
      ks_ajax :post, :create, 
           meet_up_comment: { content: @meet_up_comment.content, 
                              meet_up_id: @meet_up_comment.meet_up_id }
    end
    assert_response :success
    assert_equal "Comment was successfully created.", flash[:notice]
  end

  # Multi conference support
  test "should fail to create meet_up_comment for other conferences" do
    login_as_user
    ks_ajax :post, :create, 
         meet_up_comment: { content: "Meet up comment content", 
                            meet_up_id: meet_ups(:meet_up_for_other_conference) }
    assert_include assigns(:meet_up_comment).errors.get(:base), "user.conference_tag (generic_conference) must match MeetUpComment#conference_tag (another_conference)."
  end

  test "should show meet_up_comment" do
    ks_ajax :get, :show, id: @meet_up_comment
    assert_response :success
    assert_ponzu_frame
  end

  # Multi conference support
  test "should fail to show meet_up_comment for other conference" do
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :get, :show, id: meet_up_comments(:meet_up_comment_for_other_conference)
    end
  end

  test "should get edit" do
    login_as_admin
    ks_ajax :get, :edit, id: @meet_up_comment
    assert_response :success
    assert_ponzu_frame
  end

  test "should update meet_up_comment" do
    login_as_admin
    ks_ajax :put, :update, id: @meet_up_comment, 
            meet_up_comment: { content: @meet_up_comment.content, 
                               meet_up_id: @meet_up_comment.meet_up_id }
    assert_response :success
    assert_equal "Meet up comment was successfully updated.", flash[:notice]
  end

  # Multi conference support
  test "should fail to update meet_up_comment for other conference" do
    login_as_admin
    ks_ajax :put, :update, id: @meet_up_comment, 
            meet_up_comment: { content: @meet_up_comment.content, 
                               meet_up_id: meet_ups(:meet_up_for_other_conference) }
    assert_include assigns(:meet_up_comment).errors.get(:base), "meet_up.conference_tag (another_conference) must match MeetUpComment#conference_tag (generic_conference)."
  end

  test "should destroy meet_up_comment" do
    login_as_user
    assert_difference('MeetUpComment.count', -1) do
      ks_ajax :delete, :destroy, id: @meet_up_comment
    end

    assert_response :success
  end

  # Multi conference support
  test "should fail to destroy meet_up_comment" do
    login_as_user
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :delete, :destroy, id: meet_up_comments(:meet_up_comment_for_other_conference)
    end
  end
end
