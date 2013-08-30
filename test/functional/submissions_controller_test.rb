require 'test_helper'

class SubmissionsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  setup do
    @submission = submissions(:generic_submission)
    @request.user_agent = mountain_lion_safari_ua
    @request.host = "generic-conference.ponzu.local"
  end

  test "should get index" do
    login_as_admin
    ks_ajax :get, :index
    assert_response :success
    assert_not_nil assigns(:submissions)
    assert_include assigns(:submissions), submissions(:generic_submission)
    # Multi conference
    assert_not_include assigns(:submissions), submissions(:another_conference_submission)
  end

  test "should get new" do
    login_as_admin
    ks_ajax :get, :new
    assert_response :success
  end

  test "should create submission" do
    login_as_admin
    assert_difference('Submission.count') do
      ks_ajax :post, :create, 
              submission: [:disclose_at, :en_abstract, :en_title, :jp_abstract, :jp_title, 
                  :main_author_id, :presenting_author_id, 
                  :institutions, :keywords].inject({}){|memo, k| memo[k] = @submission.send(k); memo}.
                  merge(:submission_number => 'new_submission_number')

    end

    # Multi-conference
    assert_equal conferences(:generic_conference), assigns(:submission).conference
    assert_equal "Submission was successfully created.", flash[:notice]
    assert_response 303
  end

  test "should show submission" do
    login_as_admin
    ks_ajax :get, :show, id: @submission
    assert_response :success
  end

  # Multi-conference
  test "should not show submission for different conference" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :get, :show, id: submissions(:another_conference_submission)
    end
  end

  test "should get edit" do
    login_as_admin
    ks_ajax :get, :edit, id: @submission
    assert_response :success
  end

  # Multi-conference
  test "should not get edit for different conference" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :get, :edit, id: submissions(:another_conference_submission)
    end
  end

  test "should update submission" do
    login_as_admin
    ks_ajax :put, :update, id: @submission, submission: { disclose_at: @submission.disclose_at, en_abstract: @submission.en_abstract, en_title: @submission.en_title, jp_abstract: @submission.jp_abstract, jp_title: @submission.jp_title, main_author_id: @submission.main_author_id, presenting_author_id: @submission.presenting_author_id, submission_number: @submission.submission_number }

    # assert_redirected_to submission_path(assigns(:submission))
    assert_response :success
    assert_equal "Submission was successfully updated.", flash[:notice]
    assert_template "edit"
    assert_ponzu_frame
  end

  test "should fail to update submission for different conference" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :put, :update, id: submissions(:another_conference_submission), 
              submission: { disclose_at: @submission.disclose_at, en_abstract: @submission.en_abstract, en_title: @submission.en_title, jp_abstract: @submission.jp_abstract, jp_title: @submission.jp_title, main_author_id: @submission.main_author_id, presenting_author_id: @submission.presenting_author_id, submission_number: @submission.submission_number }
    end
  end

  test "should destroy submission" do
    login_as_admin
    assert_difference('Submission.count', -1) do
      ks_ajax :delete, :destroy, id: @submission
    end

    assert_redirected_to submissions_path
  end

  # Multi-conference
  test "should fail to destroy submission on different conference" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :delete, :destroy, id: submissions(:another_conference_submission)
    end
  end
end
