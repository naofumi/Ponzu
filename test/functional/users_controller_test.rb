require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  setup :activate_authlogic
  set_device_options :skip => [:smartphone]

  setup do
    @user = users(:generic_user)
    @request.user_agent = mountain_lion_safari_ua
    @request.host = "generic-conference.ponzu.local"
  end

  test "should get index" do
    scope_each_device :skip => [:galapagos, :smartphone] do |type|
      login_as_admin
      device_selective_request [:get, :index], type
      assert_response :success
      assert_not_nil assigns(:users)
      assert_include assigns(:users), users(:generic_user)
      # Multi conference
      assert_not_include assigns(:users), users(:user_from_different_conference)
      assert_ponzu_frame
      assert_template template_for_device(type)
      assert_absence_of_non_kamishibai_links
    end
  end

  test "should show user if no author" do
    user = users(:user_without_author)
    scope_each_device do |type|
      device_selective_request [:get, :show, id: user], type
      assert_response :success
      assert_ponzu_frame
      assert_template template_for_device(type)
      assert_absence_of_non_kamishibai_links
    end
  end

  test "should redirect user to author if has author" do
    user = users(:user_with_author)
    scope_each_device(skip: [:smartphone]) do |type|
      device_selective_request [:get, :show, id: user], type
      assert_redirected_to author_path(user.author)
    end
  end

  test "should not show user if from different conference" do
    user = users(:user_from_different_conference)
    scope_each_device do |type|
      assert_raise ActiveRecord::RecordNotFound do
        device_selective_request [:get, :show, id: user], type
      end
    end
  end

  test "should get new" do
    login_as_admin
    ks_ajax :get, :new
    assert_response :success
    assert_ponzu_frame
    assert_absence_of_non_kamishibai_links
    assert_template :new
  end

  test "should get edit" do
    login_as_admin
    ks_ajax :get, :edit, id: @user
    assert_response :success
    assert_ponzu_frame
    assert_absence_of_non_kamishibai_links
    assert_template :edit
  end

  # Multi-Conference
  test "should not allow edit if from different conference" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :get, :edit, id: users(:user_from_different_conference)
    end
  end

  test "should create user" do
    login_as_admin
    assert_difference('User.count') do
      ks_ajax :post, :create, user: { en_name: @user.en_name, jp_name: @user.jp_name,
                                      password: "12345", password_confirmation: "12345",
                                      login: "1000000" }
    end
    # Multi conference
    assert_equal conferences(:generic_conference), assigns(:user).conference
    assert_response :redirect
    assert_equal "User was successfully created.", flash[:notice]
  end


  test "should update user" do
    login_as_admin
    ks_ajax :put, :update, id: @user, user: { en_name: @user.en_name, jp_name: @user.jp_name }
    assert_response :redirect
    assert_redirected_to @user
    assert_equal "User was successfully updated.", flash[:notice]
  end

  test "should fail to update user from different conference" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :put, :update, id: users(:user_from_different_conference), 
              user: { en_name: @user.en_name, jp_name: @user.jp_name }
    end
  end

  test "should fail to destroy user with likes" do
    login_as_admin
    assert_raise ActiveRecord::DeleteRestrictionError do
      ks_ajax :delete, :destroy, id: @user
    end
  end

  test "should destroy user" do
    user_wo_likes = users(:generic_user_wo_likes)
    login_as_admin
    assert_difference('User.count', -1) do
      ks_ajax :delete, :destroy, id: user_wo_likes
    end

    assert_redirected_to users_path
  end

  test "should fail to destroy user from different conference" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :delete, :destroy, id: users(:user_from_different_conference)
    end
  end

  def test_get_settings
    scope_each_device do |type|
      login_as_user
      device_selective_request [:get, :settings, {id: users(:generic_user)}], type
      assert_response :success
      assert_ponzu_frame
      assert_absence_of_non_kamishibai_links
      assert_template :settings
    end
  end

  def test_update_settings
    scope_each_device do |type|
      login_as_user
      device_selective_request [:put, :update_settings, {id: users(:generic_user), 
                                                         user: {  en_name: @user.en_name, 
                                                                 jp_name: @user.jp_name }}], type
      assert_response :redirect
      assert_redirected_to settings_user_path(@user.id)
      assert_equal "Settings were sucessfully updated.", flash[:notice]
    end
  end

  def test_update_settings_should_fail_if_no_name_is_provided
    scope_each_device do |type|
      login_as_user
      device_selective_request [:put, :update_settings, {id: users(:generic_user),
                                                         user: {  en_name: nil, 
                                                                  jp_name: nil }}], type
      assert_response 200
      assert_equal "Failed to update settings.", flash[:error]
    end    
  end


end
