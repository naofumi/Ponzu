require 'test_helper'

class AuthorshipsControllerTest < ActionController::TestCase
  setup :activate_authlogic

  setup do
    @authorship = authorships(:to_linked_author)
    @request.user_agent = mountain_lion_safari_ua
    @request.host = "generic-conference.ponzu.local"
  end

  test "should get new" do
    login_as_admin
    ks_ajax :get, :new, :author_id => authors(:generic_author), :submission_id => submissions(:generic_submission)
    assert_response :success
    assert_select "[data-container='ponzu_frame']"    
  end

  test "create authorship should require admin" do
    login_as_user
    assert_raise CanCan::AccessDenied do
      ks_ajax :post, :create, authorship: { submission_id: authors(:generic_author), 
                                            author_id: submissions(:generic_submission_2) }
    end
  end

  test "should create authorship" do
    login_as_admin
    assert_difference('Authorship.count') do
      ks_ajax :post, :create, authorship: { author_id: authors(:generic_author), 
                                            submission_id: submissions(:generic_submission_2) }
    end
    assert_response 303
    assert_equal "Authorship was successfully created.", flash[:notice]
    assert_js_redirected_to "#!_/authorships/#{assigns(:authorship).id}"
  end

  # Multiple conference test
  test "should fail to create author for different conference" do
    login_as_admin
    ks_ajax :post, :create, 
            authorship: { en_name: "New Authorship", jp_name: "JP New Authorship",
                          author_id: authors(:generic_author),
                          submission_id: submissions(:another_conference_submission) 
                        }              
    assert_include assigns(:authorship).errors.get(:base), "Attribute conference_confirm did not match conference attribute."

  end

  test "should get edit" do
    login_as_admin
    ks_ajax :get, :edit, id: @authorship
    assert_response :success
    assert_select "[data-container='ponzu_frame']"    
  end

  test "should update authorship" do
    login_as_admin
    ks_ajax :put, :update, id: @authorship, 
                   authorship: { submission_id: submissions(:generic_submission_2), 
                                 author_id: authors(:generic_author) }
    assert_response :success
    assert_equal "Authorship was successfully updated.", flash[:notice]
  end

  # Multiple conference test
  test "should fail to update author for different conference" do
    login_as_admin
    ks_ajax :post, :update, id: @authorship,
            authorship: { submission_id: submissions(:another_conference_submission),
                          author_id: authors(:another_conference_author) }              
    assert_include assigns(:authorship).errors.get(:base), "submission.conference_tag (another_conference) must match Authorship#conference_tag (generic_conference)."
  end

  test "should destroy authorship" do
    login_as_admin
    assert_difference('Authorship.count', -1) do
      ks_ajax :delete, :destroy, id: @authorship
    end

    assert_redirected_to authorships_path
  end

  # Multiple conference test
  test "should fail to destroy authorship for different conference" do
    login_as_admin
    excp = assert_raise ActiveRecord::RecordNotFound do
      ks_ajax :delete, :destroy, id: authorships(:another_conference_authorship)
    end
  end
end
