class Session::TimeTableable < Session

  def timetable_id
    starts_at.strftime('%Y-%m-%d')
  end

  # This is the URL for the timetable on which this 
  # session is displayed
  def path(controller)
    session = self
    controller.instance_eval do
      timetable_path(session.starts_at.strftime('%Y-%m-%d'))
    end
  end
end