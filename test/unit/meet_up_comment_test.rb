require 'test_helper'

class MeetUpCommentTest < ActiveSupport::TestCase
	def setup
	  @meet_up_comment = meet_up_comments(:generic_meet_up_comment)
	end

	test "must refer to a conference" do
	  assert_equal conferences(:generic_conference), @meet_up_comment.conference
	end

	test "meet_up_comment and user conferences must match" do
	  @meet_up_comment.user = users(:user_from_different_conference)
	  assert_raise ActiveRecord::RecordInvalid do
	    @meet_up_comment.save!
	  end
	end


end
