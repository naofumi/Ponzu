require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  setup do
    @session = sessions(:generic_session)
    @request.user_agent = mountain_lion_safari_ua
    @request.host = "generic-conference.ponzu.local"
  end

  test "should get index" do
    login_as_admin
    ks_ajax :get, :index
    assert_response :success
    assert_not_nil assigns(:sessions)
    assert_ponzu_frame
    assert_include assigns(:sessions), sessions(:generic_session)
    # Multi Conference
    assert_not_include assigns(:sessions), sessions(:session_on_different_conference)
  end

  test "should get new" do
    login_as_admin
    ks_ajax :get, :new
    assert_response :success
    assert_ponzu_frame
  end

  test "should create session" do
    login_as_admin
    assert_difference('Session.count') do
      ks_ajax :post, :create, session: [:en_title, :ends_at, :jp_title, :organizers_string_en, 
                              :organizers_string_jp, 
                              :room_id, :starts_at, :type].inject({}){|memo, k| memo[k] = @session.send(k); memo}.merge(number: "new_session_number")
    end
    assert_equal "Session was successfully created.", flash[:notice]
    assert_redirected_to assigns(:session)
    # Multi conference
    assert_equal conferences(:generic_conference), assigns(:session).conference
  end

  test "should fail to create session with same number" do
    login_as_admin
    assert_no_difference('Session.count') do
      ks_ajax :post, :create, session: [:en_title, :ends_at, :jp_title, :organizers_string_en, 
                              :organizers_string_jp, 
                              :room_id, :starts_at, :type, :number].inject({}){|memo, k| memo[k] = @session.send(k); memo}
    end
    assert_equal "Failed to create Session.", flash[:error]
    assert_template :new
    # Multi conference
    assert_equal conferences(:generic_conference), assigns(:session).conference
  end

  test "should show session" do
    ks_ajax :get, :show, id: @session
    assert_response :success
    assert_json
  end

  test "should order presentations by number" do
    login_as_admin
    ks_ajax :put, :order_presentations_by_number, id: @session
    assert_response :success
    assert_template :edit
    assert_ponzu_frame
    assert_equal "Presentations were successfully reordered.", flash[:notice]
  end

  test "should set presentation times" do
    login_as_admin
    ks_ajax :put, :set_presentation_duration, id: @session, duration: '300'
    assert_response :success
    assert_template :edit
    assert_ponzu_frame
    assert_equal "Successfully modified presentation times.", flash[:notice]
  end

  test "should fail to set presentation times if duration not given" do
    login_as_admin
    ks_ajax :put, :set_presentation_duration, id: @session
    assert_response :success
    assert_template :edit
    assert_ponzu_frame
    assert_equal "Failed to modify presentation times.", flash[:error]
  end

  # Multi conference
  test "should not show session for difference conference" do
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :get, :show, id: sessions(:session_on_different_conference)
    end
  end

  test "should get edit" do
    login_as_admin
    ks_ajax :get, :edit, id: @session
    assert_response :success
    assert_ponzu_frame
  end

  # Multi conference
  test "should fail to get edit for different conference" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :get, :edit, id: sessions(:session_on_different_conference)
    end
  end

  test "should update session" do
    login_as_admin
    put :update, id: @session, 
        session: [:en_title, :ends_at, :jp_title, :organizers_string_en, 
                              :organizers_string_jp, 
                              :room_id, :starts_at, :type].inject({}){|memo, k| memo[k] = @session.send(k); memo}
    assert_response :success
    assert_ponzu_frame
  end

  # Multi Conference
  test "should fail to update session for different conference" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      put :update, id: sessions(:session_on_different_conference), 
          session: [:en_title, :ends_at, :jp_title, :organizers_string_en, 
                                :organizers_string_jp, 
                                :room_id, :starts_at, :type].inject({}){|memo, k| memo[k] = @session.send(k); memo}
    end
  end

  test "should destroy session" do
    login_as_admin
    assert_difference('Session.count', -1) do
      ks_ajax :delete, :destroy, id: sessions(:generic_session_wo_presentations)
    end

    assert_redirected_to sessions_path
  end

  test "should not destroy session with presentations" do
    login_as_admin
    assert_no_difference('Session.count') do
      ks_ajax :delete, :destroy, id: @session
    end
    assert_includes assigns(:session).errors.get(:base), "Cannot delete record because dependent presentation exist"

    assert_redirected_to @session
  end

  # Multi Conference
  test "should fail to destroy session for different conference" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :delete, :destroy, id: sessions(:session_on_different_conference)
    end
  end

end
