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

  test "new comment should be created as nested set" do
    p = presentations(:generic_presentation)
    u = users(:generic_user)
    assert_difference 'Comment.count' do
      p.comments.create!(text: "Test comment", user: u)
    end
    p.reload
    c = p.comments.last
    assert_equal nil, c.parent_id
  end

  # Replies are created by creating new comments with the parent_id set.
  test "should create reply for comment" do
    u = users(:generic_user)
    p = presentations(:generic_presentation)
    child = nil
    grandchild = nil
    assert_difference 'Comment.count' do
      child = Comment.create text: "Test reply", user: u, parent: @comment, presentation: p
    end
    assert_difference 'Comment.count' do
      grandchild = Comment.create text: "Test reply reply", user: u, parent: child, presentation: p
    end
  end
end
