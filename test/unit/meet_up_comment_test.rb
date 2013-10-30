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
	  e = assert_raise ActiveRecord::RecordInvalid do
	    @meet_up_comment.save!
	  end
	end

	test "meet_up_comment and meet_up conferences must match" do
	  @meet_up_comment.meet_up = meet_ups(:meet_up_for_other_conference)
	  e = assert_raise ActiveRecord::RecordInvalid do
	    @meet_up_comment.save!
	  end
	end

	test "should infer conference from" do
		mu = meet_ups(:generic_meet_up)
		u = users(:generic_user)
		muc = MeetUpComment.new(:meet_up => mu, :content => "Test content", :user => u)
		muc.save!
		assert muc.conference_tag = mu.conference.database_tag
	end

end
