Session::Poster

class Session::Art < Session::Poster

  # This is the URL for the poster map on which this 
  # session is displayed
  def path(controller)
    session = self
    controller.instance_eval do
      poster_session_path(session.starts_at.strftime('%Y-%m-%d'))
    end
  end

end