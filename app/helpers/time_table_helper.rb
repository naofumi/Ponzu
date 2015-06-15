module TimeTableHelper
  def timetable
    @timetable ||= begin

      # width_per_hour_conf = current_conference.config('timetable_dimensions') && 
      #                       current_conference.config('timetable_dimensions')['width_per_hour']
      # height_per_entry_conf = current_conference.config('timetable_dimensions') && 
      #                       current_conference.config('timetable_dimensions')['height_per_entry']
      # header_height_conf = 30 # height of time labels
      # time_start_left_margin = 50
      # time_on_vertical_axis_conf = true

      time_on_vertical_axis = timetable_dimensions_config(:time_on_vertical_axis)
      width_per_hour = timetable_dimensions_config(:width_per_hour) || 60.0
      height_per_entry = timetable_dimensions_config(:height_per_entry) || 80.0
      header_height = timetable_dimensions_config(:header_height) || 30
      time_start_left_margin = timetable_dimensions_config(:time_start_left_margin) || 50
      # raise [time_on_vertical_axis, width_per_hour, height_per_entry, header_height, time_start_left_margin].inspect

      @show_date ||= @session && @session.starts_at ||
                     @presentation && @presentation.starts_at ||
                     @like && @like.presentation.starts_at
      # TODO: This is very UGLY
      @rooms = Session::TimeTableable.all_in_day(@show_date).includes(:room).
               group(:room_id).order('rooms.position').map{|s| s.room}
      
      TimeTable.new :width_per_hour => width_per_hour,
             :height_per_entry => height_per_entry,
             :ranges => [@show_date.change(:hour => current_conference.timetable_hours(@show_date).first, :min => 00)..
                           @show_date.change(:hour => current_conference.timetable_hours(@show_date).last + 1, :min => 00)],
             :range_left_margins => [time_start_left_margin],
             :number_of_rooms => @rooms.size,
             :header_height => header_height, 
             :entry_vertical_margin => 2,
             :entry_horizontal_margin => 1,
             :time_on_vertical_axis => time_on_vertical_axis
    end
  end

  alias_method :tt, :timetable

  private

  def timetable_dimensions_config(symbol)
    if tt_dim = current_conference.config('timetable_dimensions')
      tt_dim[symbol.to_s]
    else
      nil
    end
  end
  
end
