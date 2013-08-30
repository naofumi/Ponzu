require 'test_helper'

class CommentTest < ActiveSupport::TestCase
	def setup
		@comment = comments(:generic_comment)
	end

  test "must refer to a conference" do
    assert_equal conferences(:generic_conference), @comment.conference
  end
end
