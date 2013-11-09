require 'test_helper'

class LikesControllerTest < ActionController::TestCase
  setup :activate_authlogic

  setup do
    @like = @like_owned_by_user = likes(:owned_by_user)
    @scheduled_by_user = likes(:scheduled_by_user)
    @request.user_agent = mountain_lion_safari_ua
    @request.host = "generic-conference.ponzu.local"
  end

  test "should get index" do
    login_as_admin
    ks_ajax :get, :index
    assert_response :success
    assert_not_nil assigns(:likes)
    assert_ponzu_frame
  end

  test "get index should fail unless login" do
    assert_raise CanCan::AccessDenied do
      ks_ajax :get, :index
    end
  end

  test "should create like" do
    login_as_user
    assert_difference('Like.count') do
      ks_ajax :post, :create, like: { presentation_id: presentations(:generic_presentation_2), 
                                      user_id: @controller.send(:current_user) }
    end

    assert_response 200
    assert_json
    assert_template :partial => "_like_button"
    assert_equal "New like was created", flash[:notice]
    assert_not_nil assigns(:like)
  end

  # Multi Conference
  test "should fail to create like for different conference" do
    login_as_user
    ks_ajax :post, :create, like: { presentation_id: presentations(:presentation_from_other_conference), 
                                    user_id: @controller.send(:current_user) }
    assert_include assigns(:like).errors.get(:base), "presentation.conference_tag (another_conference) must match Like::Like#conference_tag (generic_conference)."
  end

  test "should not create like if already present" do
    login_as_user
    assert_no_difference('Like.count') do
      ks_ajax :post, :create, like: { presentation_id: presentations(:generic_presentation), 
                                      user_id: @controller.send(:current_user) }
    end
    assert_response 200
    assert_template :partial => "_like_button"
    assert_equal "Failed to create new like", flash[:error]
  end

  test "should create like on galapagos" do
    @request.user_agent = docomo_ua
    login_as_user
    assert_difference('Like.count') do
      post :create, like: { presentation_id: presentations(:generic_presentation_2), 
                                      user_id: @controller.send(:current_user) }
    end

    assert_redirected_to assigns(:like).presentation
    assert_equal "New like was created", flash[:notice]
    assert_not_nil assigns(:like)
  end

  test "should not create like if already present on galapagos" do
    @request.user_agent = docomo_ua
    login_as_user
    assert_no_difference('Like.count') do
      post :create, like: { presentation_id: presentations(:generic_presentation), 
                                      user_id: @controller.send(:current_user) }
    end
    assert_response 302
    assert_redirected_to assigns(:like).presentation
    assert_equal "Failed to create new like", flash[:error]
  end

  test "should show like" do
    login_as_admin
    ks_ajax :get, :show, id: @like
    assert_response :success
    assert_ponzu_frame
  end

  # Multi conference support
  test "should fail to show like from different conference" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :get, :show, id: likes(:like_from_different_conference)
    end
  end

  test "should destroy like" do
    login_as_user
    assert_difference('Like.count', -1) do
      ks_ajax :delete, :destroy, id: @like_owned_by_user
    end

    assert_response :success
    assert_template :partial => '_like_button'
    assert_equal "Like was successfully removed.", flash[:notice]
  end

  test "should fail to destroy like by other person" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :delete, :destroy, id: @like_owned_by_user
    end
  end

  # Multi conference support
  test "should fail to destroy like on other conference" do
    # ActiveRecord::Base.logger = Logger.new(STDOUT)
    login_as_user
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :delete, :destroy, id: likes(:like_from_different_conference)
    end
  end

  test "should create schedule" do
    login_as_user
    ks_ajax :post, :create, like: { presentation_id: presentations(:generic_presentation_2), 
                                    user_id: @controller.send(:current_user) }
    assert_difference("Like::Schedule.count") do
      ks_ajax :put, :schedulize, :id => assigns(:like).id
    end

    assert_response 200
    assert_json
    assert_template :partial => "likes/_like_button"
    assert_equal "Successfully created Schedule.", flash[:notice]
  end

  test "should create schedule on non-ajax" do
    login_as_user
    post :create, like: { presentation_id: presentations(:generic_presentation_2), 
                           user_id: @controller.send(:current_user) }
    assert_difference("Like::Schedule.count") do
      put :schedulize, :id => assigns(:like).id
    end

    assert_redirected_to assigns(:presentation)
    assert_equal "Successfully created Schedule.", flash[:notice]
  end

  test "should remove schedule" do
    login_as_user
    assert_difference("Like::Schedule.count", -1) do
      ks_ajax :put, :unschedulize, :id => likes(:scheduled_by_user).id
    end

    assert_response 200
    assert_template :partial => "likes/_like_button"
    assert_equal "Successfully removed Schedule.", flash[:notice]
  end

  test "should create schedule on galapagos" do
    @request.user_agent = docomo_ua
    login_as_user
    post :create, like: { presentation_id: presentations(:generic_presentation_2), 
                                    user_id: @controller.send(:current_user) }
    assert_difference("Like::Schedule.count") do
      put :schedulize, :id => assigns(:like).id
    end

    assert_redirected_to assigns(:like).presentation
    assert_equal "Successfully created Schedule.", flash[:notice]
  end

  test "should remove schedule on galapagos" do
    @request.user_agent = docomo_ua
    login_as_user
    assert_difference("Like::Schedule.count", -1) do
      put :unschedulize, :id => likes(:scheduled_by_user).id
    end

    assert_redirected_to assigns(:like).presentation
    assert_equal "Successfully removed Schedule.", flash[:notice]
  end

  def test_should_get_my_likes
    login_as_user
    ks_ajax :get, :my, :id => likes(:owned_by_user).presentation.starts_at.strftime('%Y-%m-%d')
    assert_response :success
    assert_template "my"
    assert_ponzu_frame
    assert_include assigns(:likes), likes(:owned_by_user)
  end

  # Multi Conference support
  test "should fail to get my likes on a different conference" do
    login_as_user
    ks_ajax :get, :my, :id => likes(:owned_by_user).presentation.starts_at.strftime('%Y-%m-%d')
    assert_include assigns(:likes), likes(:owned_by_user)
    assert_not_include assigns(:likes), likes(:like_from_different_conference)
  end

  def test_should_get_my_schedule
    login_as_user
    ks_ajax :get, :my_schedule, :id => likes(:scheduled_by_user).presentation.starts_at.strftime('%Y-%m-%d')
    assert_response :success
    assert_template "my"
    assert_ponzu_frame
    assert_include assigns(:schedules), likes(:scheduled_by_user)
  end

  # Multi Conference support
  test "should fail to get my schedule on a different conference" do
    login_as_user
    ks_ajax :get, :my_schedule, :id => likes(:scheduled_by_user).presentation.starts_at.strftime('%Y-%m-%d')
    assert_include assigns(:schedules), likes(:scheduled_by_user)
    assert_not_include assigns(:schedules), likes(:scheduled_from_different_conference)
  end
end
