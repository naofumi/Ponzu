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

  test "must refer to a conference" do
    assert_equal conferences(:generic_conference), @session.conference
  end

end
