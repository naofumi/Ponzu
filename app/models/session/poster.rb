# == About customization
#
# For each conference, we have to use different PosterGrid classes
# because the maps are different.
#
# We try to keep the configurations in one place. Still a work in progress.
class Session::Poster < Session::Mappable
  # GRID = "PosterGrid::#{Rails.configuration.conference_module}".constantize
  # GRID = PosterGrid::Jsdb20_13

  def grid
    "PosterGrid::#{conference.module_name}".constantize
  end

  def poster_session_id
    number =~ /^(\d)(?:P|LBA)/
    $1
  end

  # This is the URL for the poster map on which this 
  # session is displayed
  def path(controller)
    session = self
    controller.instance_eval do
      poster_session_path(session.starts_at.strftime('%Y-%m-%d'))
    end
  end

end