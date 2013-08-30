# Look at the documentation on Session::Mappable to see how
# display Mappable presentations on the dynamic map.
class Presentation::Mappable < Presentation
  
  # The duration of the Presentation.
  #
  # Set to equal the duration of the session.
  def duration
    if session.ends_at && session.starts_at
      session.ends_at - session.starts_at
    else
      0
    end
  end
end