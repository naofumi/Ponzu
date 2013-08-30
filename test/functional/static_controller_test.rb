require 'test_helper'

class StaticControllerTest < ActionController::TestCase
  setup do
    @request.host = "generic-conference.ponzu.local"
  end

  test "should get rake_reports" do
    ks_ajax :get, :show, :page => 'rake_reports'
    assert_response :success
  end

end
