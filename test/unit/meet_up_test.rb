require 'test_helper'

class MeetUpTest < ActiveSupport::TestCase

  def setup
    @meet_up = meet_ups(:generic_meet_up)
  end

  test "must refer to a conference" do
    assert_equal conferences(:generic_conference), @meet_up.conference
  end

  test "meet_up and owner conferences must match" do
    @meet_up.owner = users(:user_from_different_conference)
    assert_raise ActiveRecord::RecordInvalid do
      @meet_up.save!
    end
  end

  def test_set_starts_at_through_form_params
    meet_up = MeetUp.new(:starts_at_date => "2012-12-11", 
                         :starts_at_hour => "18", 
                         :starts_at_minute => "25",
                         :title => "Test Meet Up")
    meet_up.conference = conferences(:generic_conference)
    meet_up.owner = users(:generic_user)
    meet_up.save!
    assert_equal Time.zone.parse("2012-12-11 18:25:00"), meet_up.starts_at
  end

end
