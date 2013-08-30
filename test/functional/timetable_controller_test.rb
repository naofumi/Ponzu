require 'test_helper'

class TimetableControllerTest < ActionController::TestCase

  def setup
    @request.user_agent = mountain_lion_safari_ua
    @request.host = "generic-conference.ponzu.local"
    @date = sessions(:generic_session).starts_at.strftime('%Y-%m-%d')
  end

  def test_get_show
    ks_ajax :get, :show, :id => @date
    assert_response :success
    assert_include assigns(:sessions), sessions(:generic_session)
    # Multi-conference
    assert_not_include assigns(:sessions), sessions(:session_on_different_conference)
    assert_not_include assigns(:sessions), sessions(:generic_poster_session)
  end

  test "should get list" do
  	# #list is currently only implemented on Galapagos
  	@request.user_agent = docomo_ua
  	get :list, :id => @date
  	assert_response :success
  	assert_include assigns(:sessions), sessions(:generic_session)
  	# Multi-conference
  	assert_not_include assigns(:sessions), sessions(:session_on_different_conference)
  	assert_not_include assigns(:sessions), sessions(:generic_poster_session)

  end
end
