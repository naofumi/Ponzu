class AddTimetableHourLabelsToConferences < ActiveRecord::Migration
  def change
    add_column  :conferences, :timetable_hour_labels, :string, :default => nil
  end
end
