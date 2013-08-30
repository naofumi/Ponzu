require 'test_helper'

class ConferenceDatesTest < ActiveSupport::TestCase
  def setup
    @conference = Conference.new
    @date_data = {"timetable" => ["2013-5-21", "2013-5-22", "2013-5-23"],
                  "presentation/poster" => ["2013-5-22"],
                  "meet_up" => ["2013-5-21", "2013-5-22", "2013-5-23", "2013-5-24"]}
    @conference.dates = @date_data
  end

  def test_date_strings_for
    assert_equal ["2013-5-21", "2013-5-22", "2013-5-23"], @conference.date_strings_for('timetable')
  end

  def test_dates_for
    assert_equal Time.zone.parse("2013-5-21 00:00:00"), @conference.dates_for('timetable').first
  end

  def test_closest_date_for
    assert_equal Time.zone.parse("2013-5-21 00:00:00"), 
                 @conference.closest_date_for('timetable', Time.zone.parse("2013-5-2 00:00:00"))
  end
end

