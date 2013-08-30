require 'test_helper'

class KsTestsControllerTest < ActionController::TestCase
  setup do
  end

  # test "should show page" do
  #   xhr :get, :show, page: "showcase", sub_page: "introduction"
  #   assert_response :success
  #   puts @response.body
  #   @response.recycle!
  #   puts "=============="
  #   xhr :get, :show, page: "showcase", sub_page: "key_benefits"
  #   assert_response :success
  #   puts @response.body
  # end

  test "batch" do
    skip "pending"
    get :batch
    puts @response.body
  end

end
