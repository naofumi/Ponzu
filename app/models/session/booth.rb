class Session::Booth < Session::Mappable
  # This is the URL for the poster map on which this 
  # session is displayed
  def path(controller)
    session = self
    controller.instance_eval do
      booth_session_path(session.starts_at.strftime('%Y-%m-%d'))
    end
  end
end