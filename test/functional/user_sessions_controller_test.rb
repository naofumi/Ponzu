require 'test_helper'

class UserSessionsControllerTest < ActionController::TestCase
	def setup
	  @request.user_agent = mountain_lion_safari_ua
		@request.host = "generic-conference.ponzu.local"
	end

	test "should login" do
		post :create, user_session: {login: "login_id_1",
		                             password: "benrocks"}
		assert_equal users(:generic_user), assigns(:user_session).user
		assert_not_equal users(:user_from_different_conference_with_same_login), assigns(:user_session).user
	end

	# Multi-conference support
	test "should login with same login but different conference" do
		@request.host = "another-conference.ponzu.local"
		post :create, user_session: {login: "login_id_1",
		                             password: "benrocks"}
		assert_not_equal users(:generic_user), assigns(:user_session).user
		assert_equal users(:user_from_different_conference_with_same_login), assigns(:user_session).user
	end

	test "should logout" do
		# First login
		post :create, user_session: {login: "login_id_1",
		                             password: "benrocks"}
		assert_equal users(:generic_user), assigns(:user_session).user

		delete :destroy, id: assigns(:user_session).user
		assert_nil assigns(:user_session).user
	end
end
