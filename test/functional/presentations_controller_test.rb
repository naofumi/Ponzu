require 'test_helper'

class PresentationsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  setup do
    @presentation = presentations(:generic_presentation)
    @request.user_agent = mountain_lion_safari_ua
    @request.host = "generic-conference.ponzu.local"
  end

  test "should get index" do
    ks_ajax :get, :index
    assert_response :success
    assert_not_nil assigns(:presentations)
    assert_ponzu_frame
    assert_include assigns(:presentations), presentations(:generic_presentation)
    # Multi-conference support
    assert_not_include assigns(:presentations), presentations(:presentation_from_other_conference)
  end

  test "should show presentation" do
    ks_ajax :get, :show, {id: @presentation}
    assert_response :success
    # assert_template uses String#match so we
    # can use RegExp patterns.
    # Without the '$', template 'presentations/show.g'
    # would also assert true.
    assert_template 'presentations/show$'
  end

  # Multi-conference support
  test "should not show presentation for different conference" do
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :get, :show, {id: presentations(:presentation_from_other_conference)}
    end
  end

  test "should show presentation for IE6" do
    @request.user_agent = "IE6"
    ks_ajax :get, :show, {id: @presentation}
    assert_response :success
    assert_template 'presentations/show.g$'
  end

  test "should show presentation for xhr/smartphone" do
    skip "pending"
    skip "haven't done the smartphone views yet"
    @request.user_agent = "iPhone"
    xhr :get, :show, {id: @presentation}
    assert_response :success
    assert_template 'presentations/show.g'
  end

  test "should show my presentations" do
    login_as_user
    ks_ajax :get, :my
    assert_response :success
    assert_template 'presentations/my$'
    assert_include assigns(:presentations), presentations(:generic_presentation)
    assert_not_include assigns(:presentations), presentations(:presentation_from_other_conference)
  end

  test "should not get edit if unauthorized" do
    assert_raise CanCan::AccessDenied do
      ks_ajax :get, :edit, id: @presentation
    end
  end

  test "should get edit if authorized" do
    skip "pending"
  end

  test "should update presentation" do
    login_as_admin
    ks_ajax :put, :update, id: @presentation, 
             presentation: { number: @presentation.number, ends_at: @presentation.ends_at,
                             number: @presentation.number, session_id: @presentation.session_id, 
                             starts_at: @presentation.starts_at, type: @presentation.type,
                             position: @presentation.position }
    assert_response :success
    assert_equal "Presentation was successfully updated", flash[:notice]
    assert_template "edit"
  end

  test "should fail to update presentation from different conference" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :put, :update, id: presentations(:presentation_from_other_conference), 
               presentation: { number: "new number" }
    end
  end

  test "should destroy presentation" do
    login_as_admin
    assert_difference('Presentation.count', -1) do
      ks_ajax :delete, :destroy, id: @presentation
    end

    assert_response :success
    assert_template :partial => "_list"
  end

  test "should fail to destroy presentation from different conference" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :delete, :destroy, id: presentations(:presentation_from_other_conference)
    end
  end
end
