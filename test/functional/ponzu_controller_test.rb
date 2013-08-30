require 'test_helper'

class PonzuControllerTest < ActionController::TestCase

	def setup
		@request.host = "generic-conference.ponzu.local"
	end

	test "should get current conference" do
		assert_equal "Generic Conference", @controller.send(:current_conference).name
	end
end
