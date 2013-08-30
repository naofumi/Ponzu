require 'test_helper'

class ConferenceConfirmOnAuthorTest < ActiveSupport::TestCase
	fixtures :authorships, :submissions, :conferences, :authors

	test "authors should get respective conferences" do
		a1 = authors(:generic_author)
		assert_equal conferences(:generic_conference), a1.conference
		a2 = authors(:another_conference_author)
		assert_equal conferences(:another_conference), a2.conference
	end

	# If conference_confirm is not set, then the validation will
	# not be run.
	test "should update if conference_confirm not set" do
		a1 = authors(:generic_author)
		a1.en_name = "Changed name"
		assert a1.save
	end

	test "should not update if conference_confirm is different" do
		a1 = authors(:generic_author)
		a1.en_name = "Changed name"
		a1.conference_confirm = conferences(:another_conference)
		assert_raise ActiveRecord::RecordInvalid do
			a1.save!
		end
	end

	test "should update if conference_confirm is same" do
		a1 = authors(:generic_author)
		a1.en_name = "Changed name"
		a1.conference_confirm = conferences(:generic_conference)
		a1.save
		a1.reload
		assert_equal "Changed name", a1.en_name
	end

end
