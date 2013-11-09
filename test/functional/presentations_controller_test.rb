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
    assert_json
  end

  test "should show presentation heading" do
    ks_ajax :get, :heading, {id: @presentation}
    assert_response :success
    assert_template 'presentations/heading$'
    assert_json
  end

  test "should show related presentations and galapagos" do
    @request.user_agent = "IE6"
    ks_ajax :get, :related, {id: @presentation}
    assert_response :success
    assert_template 'presentations/related.g$'
  end

  test "should not have separate related presentations view for PC and smartphones" do
    assert_raise ActionView::MissingTemplate do
      ks_ajax :get, :related, {id: @presentation}
    end
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

  test "should show my presentations" do
    login_as_user
    ks_ajax :get, :my
    assert_response :success
    assert_template 'presentations/my$'
    assert_include assigns(:presentations), presentations(:generic_presentation)
    assert_not_include assigns(:presentations), presentations(:presentation_from_other_conference)
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
               presentation: { number: "new number", type: "Presentation::Workshop" }
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

  test "should show list of likers for presentation if author" do
    login_as users(:generic_user)
    ks_ajax :get, :likes, id: @presentation
    assert_response :success
    assert_template 'presentations/likes'
    assert_include @response.body, "Liked by"
  end

  test "should decline to show list of likers for presentation unless author" do
    login_as users(:user_without_author)
    ks_ajax :get, :likes, id: @presentation
    assert_response :success
    assert_template 'presentations/likes'
    assert_include @response.body, "Only authors can"
  end

  test "should show comments" do
    ks_ajax :get, :comments, id: @presentation
    assert_response :success
    assert_template 'presentations/comments$'
    assert_json
  end
end
