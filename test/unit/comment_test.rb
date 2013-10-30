require 'test_helper'

class CommentTest < ActiveSupport::TestCase
	def setup
		@comment = comments(:generic_comment)
	end

  test "must refer to a conference" do
    assert_equal conferences(:generic_conference), @comment.conference
  end

  test "conference_tag must match presentation" do
    @comment.conference_tag = "funny_conference_tag"
    e = assert_raise ActiveRecord::RecordInvalid do
      @comment.save!
    end
  end

  test "conference should be reset" do
    @comment.conference_tag = nil
    assert @comment.save
    assert_equal conferences(:generic_conference), @comment.conference
  end
end
