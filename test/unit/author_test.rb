require 'test_helper'

class AuthorTest < ActiveSupport::TestCase
	def setup
		@author = authors(:generic_author)
	end

  test "en_name or jp_name should be set" do
  	a = @author
  	a.en_name = nil
  	a.jp_name = nil
    a.conference_confirm = conferences(:generic_conference)
    assert_raise ActiveRecord::RecordInvalid do
      a.save!
    end
  end

  test "conference_tag will be reset" do
    a = @author
    a.conference_tag = nil
    assert a.save
    assert_equal conferences(:generic_conference), a.conference
  end

  test "conference should be automatically set from submission" do
    s = submissions(:generic_submission)
    a = Author.new(:en_name => "Test name")
    a.submissions << s
    assert a.save
    assert_equal s.conference, a.conference
  end

  test "Won't accept authorship from different conference" do
    a = @author
    at = authorships(:another_conference_authorship)
    a.authorships << at
    refute at.valid? # The new authorship is not valid but doesn't raise an error yet.
    e = assert_raises ActiveRecord::RecordInvalid do
      a.save!
    end
    assert_equal "Validation failed: authorships.conference_tag (another_conference) must match Author#conference_tag (generic_conference).",
                 e.message
  end

  test "Won't accept submission from different conference" do
    a = @author
    sm = submissions(:another_conference_submission)
    e = assert_raises ActiveRecord::RecordInvalid do
      a.submissions << sm
    end
    assert_equal "Validation failed: author.conference_tag (generic_conference) must match Authorship#conference_tag (another_conference).", 
                 e.message
  end

  test "must refer to a conference" do
    assert_equal conferences(:generic_conference), @author.conference
  end
end
