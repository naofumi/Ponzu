module ConferenceDatesHelper
  # def timetable_dates
  #   ConferenceDates.dates_for(:time_table)
  #   # Rails.configuration.time_table_dates.map{|date_string| Time.zone.parse(date_string)}
  # end

  # def timetable_date_closest_to_today
  #   ConferenceDates.closest_date_for(:time_table, Time.zone.now)
  # end

  # Convert +date+(a Time.zone or Time object) to the format that we use
  # inside URLs
  def to_date_string(date)
    date.strftime('%Y-%m-%d')
  end

  # def timetable_date_closest_to_date(date)
  #   ConferenceDates.closest_date_for(:time_table, date)
  # end
end
