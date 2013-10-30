require 'test_helper'

class AuthorshipTest < ActiveSupport::TestCase
	def setup
		@authorship = authorships(:generic_authorship)
	end

  test "must refer to a conference" do
    assert_equal conferences(:generic_conference), @authorship.conference
  end

  test "validate submission and author conference must match" do
  	@authorship.submission = submissions(:another_conference_submission)
  	e = assert_raises ActiveRecord::RecordInvalid do
	  	@authorship.save!
	  end
    assert_equal "Validation failed: submission.conference_tag (another_conference) must match Authorship#conference_tag (generic_conference).", e.message
  end
end
