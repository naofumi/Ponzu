module TimeTableHelper
  def timetable
    @timetable ||= begin
      width_per_hour_conf = current_conference.config('timetable_dimensions') && 
                            current_conference.config('timetable_dimensions')['width_per_hour']
      height_per_entry_conf = current_conference.config('timetable_dimensions') && 
                            current_conference.config('timetable_dimensions')['height_per_entry']


      width_per_hour = width_per_hour_conf || 60.0
      height_per_entry = height_per_entry_conf || 80.0


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
             :range_left_margins => [50],
             :number_of_rooms => @rooms.size,
             :header_height => 30, 
             :entry_vertical_margin => 2,
             :entry_horizontal_margin => 1
    end
  end
  
  alias_method :tt, :timetable
  
end
