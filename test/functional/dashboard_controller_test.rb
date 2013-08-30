require 'test_helper'

class DashboardControllerTest < ActionController::TestCase
	def setup
    @request.user_agent = mountain_lion_safari_ua
    @request.host = "generic-conference.ponzu.local"
	end
	def test_get_index
		ks_ajax :get, :index
		assert_response :success
		assert_ponzu_frame
	end
end
