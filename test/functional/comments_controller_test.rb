# encoding: utf-8
require 'test_helper'

class CommentsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  setup do
    @comment = comments(:generic_comment)
    @request.user_agent = mountain_lion_safari_ua
    @request.host = "generic-conference.ponzu.local"
  end

  test "should get index" do
    login_as_admin
    ks_ajax :get, :index
    assert_response :success
    assert_not_nil assigns(:comments)
    assert_ponzu_frame
  end

  test "should get new" do
    login_as_admin
    ks_ajax :get, :new
    assert_response :success
    assert_ponzu_frame
  end

  test "should create comment" do
    login_as_user
    assert_difference('Comment.count') do
      ks_ajax :post, :create, 
              comment: { presentation_id: @comment.presentation_id, 
                         text: @comment.text, 
                         user_id: users(:generic_user).id }
    end

    assert_response :success
    assert_template :show
    assert_equal "コメントを作成しました", flash[:notice]
    assert_ponzu_frame
  end

  # Multiple conference test
  test "should fail to create comment if conferences for user and presentation do not match" do
    login_as_user
    assert_no_difference('Comment.count') do
      ks_ajax :post, :create, 
              comment: { presentation_id: @comment.presentation_id, 
                         text: @comment.text, 
                         user_id: users(:user_from_different_conference).id }
    end
  end

  # Multiple conference test
  test "should fail to create comment for other conference" do
    login_as_user
    ks_ajax :post, :create, 
            comment: { presentation_id: presentations(:presentation_from_other_conference), 
                       text: @comment.text, 
                       user_id: users(:generic_user).id }
    assert_include assigns(:comment).errors.get(:base), "Attribute conference_confirm did not match conference attribute."
  end

  test "should show comment" do
    login_as_admin
    ks_ajax :get, :show, id: @comment
    assert_response :success
    assert_ponzu_frame
  end

  # Multiple conference test
  test "should fail to show comment from other conference" do
    login_as_admin
    exception = assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :get, :show, id: comments(:comment_from_other_conference)
    end
  end

  test "should get edit" do
    login_as_admin
    ks_ajax :get, :edit, id: @comment
    assert_response :success
    assert_ponzu_frame
  end

  test "should update comment" do
    login_as_admin
    ks_ajax :put, :update, id: @comment, 
            comment: { presentation_id: @comment.presentation_id, 
                       text: @comment.text, 
                       user_id: @comment.user_id }
    assert_response :success
    assert_equal "コメントが正しくアップデートされました", flash[:notice]
  end

  # Multiple conference test
  test "should fail to update comment to other conference" do
    login_as_admin
    ks_ajax :put, :update, id: @comment, 
            comment: { presentation_id: presentations(:presentation_from_other_conference), 
                       text: @comment.text, 
                       user_id: @comment.user_id }
    assert_include assigns(:comment).errors.get(:base), "Attribute conference_confirm did not match conference attribute."
  end

  test "should destroy comment" do
    login_as_user
    assert_difference('Comment.count', -1) do
      ks_ajax :delete, :destroy, id: @comment
    end

    assert_response :success
  end

  test "should fail to destroy other user's comment" do
    login_as(users(:generic_user_2))
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :delete, :destroy, id: @comment
    end
  end

  # Multiple conference test
  test "should fail to destroy comment on other conference" do
    login_as_user
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :delete, :destroy, id: comments(:comment_from_other_conference)
    end
  end
end
