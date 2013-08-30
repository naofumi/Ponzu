require 'test_helper'

class AuthorsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  setup do
    @author = authors(:generic_author)
    @request.user_agent = mountain_lion_safari_ua
    @request.host = "generic-conference.ponzu.local"
  end

  test "should get index if admin" do
    login_as_admin
    ks_ajax :get, :index
    assert_response :success
    assert_not_nil assigns(:authors)
  end

  test "should fail get index unless admin" do
    login_as_user
    assert_raise CanCan::AccessDenied do
      ks_ajax :get, :index
    end
  end

  test "should get new if admin" do
    login_as_admin
    ks_ajax :get, :new
    assert_response :success
  end

  test "should fail to get new unless admin" do
    login_as_user
    assert_raise CanCan::AccessDenied do
      ks_ajax :get, :new
    end
  end

  test "should create author" do
    login_as_admin
    assert_difference('Author.count') do
      ks_ajax :post, :create, 
              author: { en_name: "New Author", jp_name: "JP New Author",
                        initial_submission: submissions(:generic_submission).id
                      }              
    end
    assert_equal "Author was successfully created", flash[:notice]
    assert_response 303
    assert_js_redirected_to "#!_/authors/#{assigns(:author).id}/edit"
    # assert_redirected_to author_path(assigns(:author))
  end

  # Multiple conference test
  test "should fail to create author for different conference" do
    login_as_admin
    ks_ajax :post, :create, 
            author: { en_name: "New Author", jp_name: "JP New Author",
                      initial_submission: submissions(:another_conference_submission).id
                    }
    assert_include assigns(:author).errors.get(:base), "Attribute conference_confirm did not match conference attribute."
  end

  test "should show author" do
    ks_ajax :get, :show, id: @author
    assert_response :success
  end

  # Multiple conference test
  test "should fail to show author for different conference" do
    author = authors(:another_conference_author)
    excp = assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :get, :show, id: author
    end
  end

  test "should get edit" do
    login_as_admin
    ks_ajax :get, :edit, id: @author
    assert_response :success
  end

  test "should fail to get edit unless admin" do
    login_as_user
    assert_raise CanCan::AccessDenied do
      ks_ajax :get, :edit, id: @author
    end
  end

  test "should update author" do
    login_as_admin
    ks_ajax :put, :update, id: @author, author: { en_name: @author.en_name, jp_name: @author.jp_name }
    assert_equal "Author was successfully updated.", flash[:notice]
    assert_response :success
  end

  test "should destroy author" do
    login_as_admin
    assert_difference('Author.count', -1) do
      ks_ajax :delete, :destroy, id: @author
    end

    assert_redirected_to authors_path
  end
end
