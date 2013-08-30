require 'test_helper'

class LikeTest < ActiveSupport::TestCase
	def setup
		@like = likes(:owned_by_user)
	end

  test "must refer to a conference" do
    assert_equal conferences(:generic_conference), @like.conference
  end

  test "presentation and user conferences must match" do
  	like = Like.new(:user_id => users(:user_from_different_conference).id, 
  	                :presentation_id => presentations(:generic_presentation).id,
  	                :type => 'Like::Like')
  	assert_raise ActiveRecord::RecordInvalid do
  		like.save!
  	end
  end
end
