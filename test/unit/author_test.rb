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

  test "must refer to a conference" do
    assert_equal conferences(:generic_conference), @author.conference
  end
end
