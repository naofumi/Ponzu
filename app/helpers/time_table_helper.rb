module TimeTableHelper
  def timetable(options = {})
    width_per_hour = options[:width_per_hour] || 60.0
    height_per_entry = options[:height_per_entry] || 80.0
    @timetable ||= begin
      @show_date ||= @session && @session.starts_at ||
                     @presentation && @presentation.starts_at ||
                     @like && @like.presentation.starts_at
      # TODO: This is very UGLY
      @rooms = Session::TimeTableable.all_in_day(@show_date).includes(:room).
               group(:room_id).order('rooms.position').map{|s| s.room}
      
      TimeTable.new :width_per_hour => width_per_hour,
             :height_per_entry => height_per_entry,
             :ranges => [@show_date.change(:hour => 8, :min => 00)..
                           @show_date.change(:hour => 21, :min => 00)],
             :range_left_margins => [50],
             :number_of_rooms => @rooms.size,
             :header_height => 30, 
             :entry_vertical_margin => 2,
             :entry_horizontal_margin => 1
    end
  end
  
  alias_method :tt, :timetable
  
  def mobile_timetable
    timetable(:width_per_hour => 60.0, :height_per_entry => 75.0)
  end
  
  alias_method :mtt, :mobile_timetable

end
