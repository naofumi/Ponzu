require 'test_helper'

class MeetUpsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  setup do
    @meet_up = meet_ups(:generic_meet_up)
    @request.user_agent = mountain_lion_safari_ua
    @request.host = "generic-conference.ponzu.local"
  end

  test "should get index" do
    scope_each_device(skip: [:smartphone]) do |type|
      date_param = conferences(:generic_conference).date_strings_for('meet_up').last
      device_selective_request [:get, :index, :date => date_param], type
      assert_response :success
      assert_not_nil assigns(:meet_ups)
      assert_ponzu_frame
      assert_template template_for_device(type)
      assert_absence_of_non_kamishibai_links
    end
  end

  test "should automatically select closest date" do
    ks_ajax :get, :index
    assert_equal conferences(:generic_conference).dates_for('meet_up').last, assigns(:show_date)
  end

  # Multi conference
  test "should not get index for other conference" do
    ks_ajax :get, :index, :date => '2012-05-21'
    assert_include assigns(:meet_ups), meet_ups(:generic_meet_up)
    assert_not_include assigns(:meet_ups), meet_ups(:meet_up_for_other_conference)
  end

  test "should fail to get new if not logged in" do
    scope_each_device(skip: [:smartphone]) do |type|
      assert_raise CanCan::AccessDenied do
        device_selective_request [:get, :new], type
      end
    end
  end

  test "should get new" do
    scope_each_device(skip: [:smartphone, :galapagos]) do |type|
      login_as_user
      device_selective_request [:get, :new], type
      assert_template template_for_device(type)
      assert_response :success
      assert_ponzu_frame
    end
  end

  test "should create meet_up" do
    scope_each_device(skip: [:smartphone, :galapagos]) do |type|
      login_as_user
      assert_difference('MeetUp.count') do
        ks_ajax :post, :create, 
                meet_up: { title: @meet_up.title,
                           description: @meet_up.description, 
                           meet_at: @meet_up.meet_at, 
                           starts_at: @meet_up.starts_at, 
                           venue: @meet_up.venue, 
                           venue_url: @meet_up.venue_url }
      end

      assert_response 303
      assert_js_redirected_to "#!_/meet_ups/#{assigns[:meet_up].id}"
      assert_equal "Successfully created Yoruzemi", flash[:notice]
      assert_equal ["/meet_ups?date=#{@meet_up.starts_at.strftime('%Y-%m-%d')}"], 
                   JSON.parse(@response.headers["X-Invalidate-Cache-Paths"])
    end
  end

  test "should fail to create meet_up" do
    scope_each_device(skip: [:smartphone, :galapagos]) do |type|
      login_as_user
      assert_no_difference('MeetUp.count') do
        ks_ajax :post, :create, 
                meet_up: { title: nil,
                           description: @meet_up.description, 
                           meet_at: @meet_up.meet_at, 
                           starts_at: @meet_up.starts_at, 
                           venue: @meet_up.venue, 
                           venue_url: @meet_up.venue_url }
      end

      assert_response 200
      assert_template :new
      assert_equal nil, flash[:notice]
      assert_equal "Failed to create Yoruzemi", flash[:error]
    end
  end

  test "should show meet_up" do
    scope_each_device(skip: [:smartphone, :galapagos]) do |type|
      ks_ajax :get, :show, id: @meet_up
      assert_response :success
      assert_ponzu_frame
    end
  end

  test "should get edit" do
    scope_each_device(skip: [:smartphone, :galapagos]) do |type|
      login_as @meet_up.owner
      ks_ajax :get, :edit, id: @meet_up
      assert_response :success
      assert_ponzu_frame
    end
  end

  test "should not get edit if not owner user" do
    scope_each_device(skip: [:smartphone, :galapagos]) do |type|
      login_as(users(:generic_user_2))
      assert_raise CanCan::AccessDenied do
        ks_ajax :get, :edit, id: @meet_up
      end
    end
  end

  test "should update meet_up" do
    scope_each_device(skip: [:smartphone, :galapagos]) do |type|
      login_as @meet_up.owner
      ks_ajax :put, :update, id: @meet_up, 
               meet_up: { description: @meet_up.description, 
                          meet_at: @meet_up.meet_at, 
                          owner_id: @meet_up.owner_id, 
                          starts_at: @meet_up.starts_at, 
                          venue: @meet_up.venue, 
                          venue_url: @meet_up.venue_url }
      assert_equal "Yoruzemi was successfully updated.", flash[:notice]
      assert_response 303
      assert_js_redirected_to "#!_/meet_ups/#{@meet_up.id}"
    end
  end

  test "should destroy meet_up" do
    scope_each_device(skip: [:smartphone, :galapagos]) do |type|
      login_as_admin
      assert_difference('MeetUp.count', -1) do
        ks_ajax :delete, :destroy, id: @meet_up
      end

      assert_equal "Sucessfully destroyed meet up", flash[:notice]
      # assert_redirected_to meet_ups_path
    end
  end

  test "owner cannot destroy meet_up" do
    scope_each_device(skip: [:smartphone, :galapagos]) do |type|
      login_as @meet_up.owner
      assert_raise CanCan::AccessDenied do
        ks_ajax :delete, :destroy, id: @meet_up
      end
    end
  end

  test "should fail to destroy meet up on different conference" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :delete, :destroy, id: meet_ups(:meet_up_for_other_conference)
    end
  end

end
