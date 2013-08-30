require 'test_helper'

class PosterSessionsControllerTest < ActionController::TestCase
  setup do
    @request.user_agent = mountain_lion_safari_ua
    @request.host = "generic-conference.ponzu.local"
    @date = sessions(:generic_poster_session).starts_at.strftime('%Y-%m-%d')
  end

  def test_show
    ks_ajax :get, :show, :id => @date
    assert_response :success
    assert_include assigns(:sessions), sessions(:generic_poster_session)
    assert_not_include assigns(:sessions), sessions(:poster_session_on_different_conference)
    assert_not_include assigns(:sessions), sessions(:generic_session)
  end

  def test_list
    ks_ajax :get, :list, :id => @date
    assert_response :success
    assert_include assigns(:sessions), sessions(:generic_poster_session)
    assert_not_include assigns(:sessions), sessions(:poster_session_on_different_conference)
    assert_not_include assigns(:sessions), sessions(:generic_session)
  end

  def test_like_highlights
    skip "Pending"
  end
end
