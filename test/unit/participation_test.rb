require 'test_helper'

class ParticipationTest < ActiveSupport::TestCase
  def setup
    @particpation = participations(:generic_participation)
  end

  test "must refer to a conference" do
    assert_equal conferences(:generic_conference), @particpation.conference
  end

  test "validate user conference must match" do
    @particpation.user = users(:user_from_different_conference)
    e = assert_raises ActiveRecord::RecordInvalid do
      @particpation.save!
    end
  end

  test "validate meet_up conference must match" do
    @particpation.meet_up = meet_ups(:meet_up_for_other_conference)
    e = assert_raises ActiveRecord::RecordInvalid do
      @particpation.save!
    end
  end

  test "conference_tag should be reset" do
    @particpation.conference_tag = nil
    assert @particpation.save
    assert_equal conferences(:generic_conference), @particpation.conference
  end

end
