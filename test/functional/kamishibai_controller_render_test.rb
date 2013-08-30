require 'test_helper'

# Test the Kamishibai controller 
# methods that extend the render.
class KamishibaiControllerRenderTest < ActionController::TestCase
  tests ApplicationController

  def setup
    # Stub
    def @controller.device_scope_by_user_agent
      Kamishibai::DeviceSupport::DESKTOP_URL_SCOPE
    end
  end

  def test_ksp_string_type
    assert_equal "#!_/hello/show", @controller.send(:ksp, '/hello/show')
  end

  def test_ksp_nil_type
    assert_equal "#!_/", @controller.send(:ksp, nil)
  end

  def test_ksp_symbol_type
    assert_equal "#!_/users", @controller.send(:ksp, :users_path)
    assert_equal "#!_/users/123", @controller.send(:ksp, :user_path, :id => 123)
    assert_equal "#!_/users/123?page=2", @controller.send(:ksp, :user_path, 123, :page => 2)
  end

  def test_ksp_resource_type
    user = users(:generic_user)
    assert_equal "#!_/users/#{user.id}", @controller.send(:ksp, user)
  end

  def test_ksp_symbol_type_with_id
    assert_equal "#!_/users/123__some_id", 
                 @controller.send(:ksp, [:user_path, "some_id"], 123)
  end

  def test_ksp_symbol_type_with_id
    assert_equal "#!_/hello/show__some_id", 
                 @controller.send(:ksp, ["/hello/show", "some_id"])
  end

  def test_ksp_with_bootloader_path
    user = users(:generic_user)
    assert_equal "http://test.host#!_/users/#{user.id}", 
                 @controller.send(:ksp, user, :bootloader_path => "http://test.host")
  end

end
