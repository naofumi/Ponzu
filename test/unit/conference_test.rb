require 'test_helper'

class ConferenceTest < ActiveSupport::TestCase
	def setup
		@conference = Conference.new
		@date_data = {"timetable" => ["2013-5-21", "2013-5-22", "2013-5-23"],
			            "presentation/poster" => ["2013-5-22"],
			            "meet_up" => ["2013-5-21", "2013-5-22", "2013-5-23", "2013-5-24"]}
	end

	test "dates should accept complex data" do
    @conference.dates = @date_data
    @conference.save!
    @conference.reload
    assert_equal @date_data, @conference.dates
	end

	test "should get closest date" do
		@conference.dates = @date_data
		assert_equal Time.zone.parse("2013-5-23"), 
		             @conference.closest_date_for('timetable', Time.zone.parse("2013-6-1"))
		assert_equal Time.zone.parse("2013-5-22"), 
		             @conference.closest_date_for("presentation/poster", Time.zone.parse("2013-6-1"))
		assert_equal Time.zone.parse("2013-5-24"), 
		             @conference.closest_date_for("meet_up", Time.zone.parse("2013-6-1"))

	end
end
