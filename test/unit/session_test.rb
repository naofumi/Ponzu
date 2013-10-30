require 'test_helper'

class SessionTest < ActiveSupport::TestCase

  def setup
    @session = sessions(:generic_session)
  end

  def test_order_presentations_by_number
    session = sessions(:session_for_ordering)
    session.order_presentations_by_number
    assert_equal ["first_in_session", "last_in_session", "second_in_session"], 
                  session.presentations.map{|p| p.number}
  end

  def test_set_presentation_times_by_duration
    session = sessions(:session_for_ordering)
    session.set_presentation_times_by_duration(10)
    assert_equal session.starts_at, session.presentations[0].starts_at
    assert_equal session.starts_at + 10 * 60, session.presentations[0].ends_at
    assert_equal session.starts_at + 10 * 60, session.presentations[1].starts_at
  end

  test "two sessions in same conference cannot share same number" do
    session_two = sessions(:generic_session_2)
    session_two.number = @session.number
    e = assert_raise ActiveRecord::RecordInvalid do
      session_two.save!
    end
    assert_equal "Validation failed: Number has already been taken", e.message
  end

  test "must refer to a conference" do
    assert_equal conferences(:generic_conference), @session.conference
  end

  test "conference_tags for session and room must match" do
    @session.room = rooms(:room_for_different_conference)
    e = assert_raises ActiveRecord::RecordInvalid do
      @session.save!
    end
  end

  test "two sessions belonging to difference conferences can have same number" do
    session_two = sessions(:session_on_different_conference)
    session_two.number = @session.number
    assert session_two.save
  end

end
