class Presentation::TimeTableable < Presentation
  # The duration of the Presentation.
  #
  # If ends_at is not set in the presentation object,
  # calculated using #start_at of the next Presentation,
  # of the #ends_at of the Session if this is the last Presentation.
  def duration
    return 0 unless starts_at
    if ends_at
      ends_at - starts_at
    elsif lower_item && lower_item.starts_at
      lower_item.starts_at - starts_at
    elsif session.ends_at
      session.ends_at - starts_at
    else
      0
    end
  end

end