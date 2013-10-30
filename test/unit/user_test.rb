require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:generic_user)
    # @global_message = global_messages(:generic_global_message)
  end

  def test_should_get_read_global_messages
    skip("Will probably rewrite to use notifications")
    assert_include @user.unread_global_messages, @global_message
  end

  def test_set_read_global_message
    skip("Will probably rewrite to use notifications")
    @user.set_global_message_to_read(@global_message)
    assert_not_include @user.unread_global_messages, @global_message
    assert_include @user.read_global_messages, @global_message
  end
  
  def test_set_global_message_to_unread
    skip("Will probably rewrite to use notifications")
    @user.set_global_message_to_read(@global_message)
    assert_not_include @user.unread_global_messages, @global_message
    @user.set_global_message_to_unread(@global_message)
    assert_include @user.unread_global_messages, @global_message
  end

  test "create user" do
    assert_difference('User.count') do
      new_user = User.new(login: "some_login", password: "some_password", 
                password_confirmation: "some_password", en_name: "some name")
      new_user.conference_id = "13435451" # workaround until we get rid of User#conference_id
      new_user.conference_tag = 'generic_conference'
      new_user.save!
    end
  end

  test "new user requires conference to be set" do
    new_user = User.new(login: "some_login", password: "some_password", 
              password_confirmation: "some_password", en_name: "some name")
    assert_raise ActiveRecord::RecordInvalid do
      new_user.save!
    end
  end

  test "cannot create users with same login if conferences are same" do
    old_user = users(:generic_user_2)
    new_user = User.new(login: old_user.login, password: "benrocks", 
              password_confirmation: "benrocks", en_name: "some name")
    new_user.conference_tag = old_user.conference_tag
    new_user.conference_id = "13435451" # workaround until we get rid of User#conference_id
    assert_raise ActiveRecord::RecordInvalid do
      new_user.save!
    end
  end

  test "can create users with same login if conferences are different" do
    old_user = users(:generic_user_2)
    new_user = User.new(login: old_user.login, password: "benrocks", 
              password_confirmation: "benrocks", en_name: "some name")
    new_user.conference_tag = "another_conference"
    new_user.conference_id = "13435451" # workaround until we get rid of User#conference_id
    assert_difference('User.count') do
      new_user.save!
    end
  end
end
