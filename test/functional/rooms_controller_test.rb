require 'test_helper'

class RoomsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  setup do
    @room = rooms(:generic_room)
    @request.user_agent = mountain_lion_safari_ua
    @request.host = "generic-conference.ponzu.local"
  end

  test "should get index" do
    ks_ajax :get, :index
    assert_response :success
    assert_not_nil assigns(:rooms)
    assert_ponzu_frame
    assert_include assigns(:rooms), @room
    # Multi-confererence
    assert_not_include assigns(:rooms), rooms(:room_for_different_conference)
  end

  test "should get new" do
    login_as_admin
    ks_ajax :get, :new
    assert_response :success
    assert_ponzu_frame
  end

  test "should create room" do
    login_as_admin
    assert_difference('Room.count') do
      ks_ajax :post, :create, room: [:jp_name , :en_name, :jp_location, 
                           :en_location, :map_url, :pin_top, 
                           :pin_left].inject({}){|memo, k| @room.send(k)}
    end
    assert_response :success
    assert_equal "Room was successfully created.", flash[:notice]
    assert_template 'edit'
    # assert_redirected_to room_path(assigns(:room))
  end

  test "should show room" do
    ks_ajax :get, :show, id: @room
    assert_response :success
  end

  # Multi-conference
  test "should not show room for other conference" do
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :get, :show, id: rooms(:room_for_different_conference)
    end
  end

  test "should get edit" do
    login_as_admin
    ks_ajax :get, :edit, id: @room
    assert_response :success
    assert_ponzu_frame
  end

  # Multi-conference
  test "should not get edit room for other conference" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :get, :edit, id: rooms(:room_for_different_conference)
    end
  end

  test "should update room" do
    login_as_admin
    ks_ajax :put, :update, id: @room, room: [:jp_name , :en_name, :jp_location, 
                           :en_location, :map_url, :pin_top, 
                           :pin_left].inject({}){|memo, k| @room.send(k)}
    assert_response :success
    assert_ponzu_frame
  end

  # Multi-conference
  test "should fail to update room for other conference" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :put, :update, id: rooms(:room_for_different_conference), 
                      room: [:jp_name , :en_name, :jp_location, 
                             :en_location, :map_url, :pin_top, 
                             :pin_left].inject({}){|memo, k| @room.send(k)}
    end
  end

  test "should destroy room" do
    login_as_admin
    assert_difference('Room.count', -1) do
      ks_ajax :delete, :destroy, id: @room
    end

    assert_redirected_to rooms_path
  end

  # Multi-conference
  test "should fail to destroy room for different conference" do
    login_as_admin
    assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :delete, :destroy, id: rooms(:room_for_different_conference)
    end
  end
end
