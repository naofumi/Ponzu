# TimeTable calculates pixel positions for
# display in a time table.
#
# We want to make this class as intelligent as possible so
# as to ease the burden on the view. It can generate CSS.
#
# Ideally, we just want to plunk down a list of objects.
# We would add a list of sessions or likes and the object 
# will do necessary calculations.
#
# Each object representing an entry must have a +starts_at+
# and +ends_at+ method.
#
# We also want objects representing the rows. Each entry
# object will be called a method (i.e. #room) and the result will
# be compared to the row objects. This tells us where to place
# the object.
require File.expand_path('../../../lib/range_set', __FILE__)
require 'conference_dates'
class TimeTable
  attr_reader :width_per_hour, :height_per_entry
  Dimensions = Struct.new(:left, :right, :top, :bottom, :height, :width)
  include ConferenceDates

  # Create a TimeTable object. TimeTable objects tell at which CSS coordinates
  # to draw certain times, sessions, time labels and room labels.
  #
  # To initialize a TimeTable object, we have to provide information about
  # the how the TimeTable should appear. The options are as follows. All
  # numbers are in pixels (px).
  #
  # <tt>:width_per_hour</tt>::
  #   The width per hour. This sets the horizontal scale. Smaller values
  #   cause the timetable to be narrower. Larger values make it wider.
  # 
  # <tt>:height_per_entry</tt>::
  #   The height per timetable entry. This is the same as the height of
  #   each row. This sets the vertical scale.
  #
  # <tt>:rooms</tt>::
  #   *Deprecated* This is a list of the Room objects that will be shown in
  #   this timetable. We deprecated this in favor of the +:number_of_rooms+
  #   option. Instead of setting +:rooms+ with an Array or Room objects, simply
  #   supply the number of rooms in the +:number_of_rooms+ option. This value
  #   is currently not used.
  #
  # <tt>:labeled_hours</tt>::
  #   *Deprecated* This is a list of the time labels that we use for the
  #   headers. Deprecated because TimeTable now only tells us where to 
  #   draw each header; it does not involve itself with what the labels should
  #   be like, since that should be a +View+ matter. This value is currently not used.
  #
  # <tt>:ranges</tt>::
  #   This options should contain an Array of Ranges. Each Range specifies
  #   a range of time which specifies a continous strech of time in the
  #   TimeTable. This is illustrated in the following.
  #   
  #   Suppose we wanted had sessions in the following times, and a break in between.
  #
  #   08:00 - 10:00, 15:00 - 19:30
  #
  #   Then we would want to strip out the middle 10:00 - 15:00 from the timetable
  #   since it would just be a blank. Then we would specify +:ranges+ in the following way;
  #
  #     :ranges => [time_for(8,0)..time_for(10, 00), time_for(15, 0)..time_for(19, 30)]
  #
  # <tt>:range_left_margins</tt>::
  #   This specifies the left margin for each range specified above. For example;
  #
  #     :range_left_margins => [100, 100]
  #
  #   The above options specifies that the first time range would be 100px away from
  #   the leftmost position. This would normally provide space to put the names of the rooms.
  #
  #   Similarly, the second time range would specify the width of the "gap" between 10:00 and 15:00.
  #
  # <tt>:header_height</tt>::
  #   This specifies the height of the header, which is where we put the hour labels.
  #
  # <tt>:time_on_vertical_axis</tt>::
  #   This specifies whether the time will be shown on the horizontal axis (if false)
  #   or on the vertical axis (if true). When this is set to true, the width and height
  #   parameters all switch their meaning.
  def initialize(options)
    @width_per_hour = options[:width_per_hour]
    @height_per_entry = options[:height_per_entry]
    @range_set = RangeSet.new *options[:ranges]
    @range_left_margins = options[:range_left_margins]
    @header_height = options[:header_height]
    @rooms = options[:rooms]
    @labeled_hours = options[:labeled_hours]
    @number_of_rooms = options[:number_of_rooms]
    @entry_horizontal_margin = options[:entry_horizontal_margin] || 0
    @entry_vertical_margin = options[:entry_vertical_margin] || 0
    @time_on_vertical_axis = options[:time_on_vertical_axis]
  end
    
  def left_position_for_time(time)
    position = @range_set.position(time)
    if position
      range_left_position(position.range_index) +
      seconds_to_hours(position.left) * @width_per_hour
    else
      nil
    end
  end
  
  def room_label_width
    unless @time_on_vertical_axis
      @range_left_margins[0]
    end
  end

  def room_label_height
    if @time_on_vertical_axis
      @range_left_margins[0]
    end
  end

  def range_left_position(range_index)
    margins = 0.upto(range_index).inject(0){|memo, i| memo + @range_left_margins[i]}
    widths = range_index > 0 ?
               0.upto(range_index - 1).inject(0){|memo, i| memo + width_of_range(@range_set[i])} :
               0
    margins + widths
  end

  def width_of_range(range)
    (range.max - range.min) * width_per_second
  end

  def row(row_number)
    left = 0
    width = (@time_on_vertical_axis ? total_height : total_width)
    top = row_number * @height_per_entry + @header_height
    height = @height_per_entry
    unless @time_on_vertical_axis
      Dimensions.new(left, left + width, top, top + height, height, width)
    else      
      Dimensions.new(top, top + height, left, left + width, width, height)
    end
  end

  def row_css(row_number)
    r = row(row_number)
    "position:absolute;left:#{r.left}px;top:#{r.top}px;height:#{r.height}px;width:#{r.width}px"
  end

  # Each entry in the timetable for each session
  def entry(options)
    left = left_position_for_time options[:starts_at]
    right = left_position_for_time options[:ends_at]
    raise "Position out of range starts_at:#{options[:starts_at]} ends_at:#{options[:ends_at]}" unless left && right
    width = right - left
    height = options[:height] || @height_per_entry

    top = options[:row] * height + @header_height
    unless @time_on_vertical_axis
      return Dimensions.new(left + @entry_horizontal_margin, 
                            left + width - @entry_horizontal_margin, 
                            top + @entry_vertical_margin, 
                            top + height - @entry_vertical_margin, 
                            height - @entry_vertical_margin * 2, 
                            width - @entry_horizontal_margin * 2)
    else
      return Dimensions.new(
                            top + @entry_vertical_margin, 
                            top + height - @entry_vertical_margin, 
                            left + @entry_horizontal_margin, 
                            left + width - @entry_horizontal_margin,  
                            width - @entry_horizontal_margin * 2,
                            height - @entry_vertical_margin * 2)
    end
  end

  def entry_css(options)
    e = entry(options)
    "top:#{e.top}px;left:#{e.left}px;height:#{e.height}px;width:#{e.width}px"
  end

  # Headers in which we put time labels
  def header(time)
    left = left_position_for_time time
    width = width_per_hour
    top = 0
    height = @header_height
    unless @time_on_vertical_axis
      Dimensions.new(left, left + width, top, top + height, height, width)
    else
      Dimensions.new(top, top + height, left, left + width, width, height)
    end
  end

  def header_css(time)
    h = header(time)
    "top:#{h.top}px;left:#{h.left}px;width:#{h.width}px;height:#{h.height}px"
  end
  
  def width_per_hour
    @width_per_hour
  end

  def width_per_second
    @width_per_hour / 3600.0
  end

  def width_per_minute
    @width_per_hour / 60.0
  end
  
  def total_height
    if @time_on_vertical_axis
      total_width_when_time_on_horizontal_axis
    else
      total_height_when_time_on_horizontal_axis
    end
  end

  def total_height_when_time_on_horizontal_axis
    @number_of_rooms * (@height_per_entry + @entry_vertical_margin) + @header_height
  end

  def total_width
    if @time_on_vertical_axis
      total_height_when_time_on_horizontal_axis
    else
      total_width_when_time_on_horizontal_axis
    end
  end

  def total_width_when_time_on_horizontal_axis
    range_left_position(@range_set.count - 1) + width_of_range(@range_set.last)
  end

  def presentation_tag_css(starts_at, ends_at, row_number)
    default_duration = 20 #minutes
    default_size = 10
    d = entry(:starts_at => starts_at,
                 :ends_at => ends_at || starts_at + default_duration * 60,
                 :row => row_number)
    unless @time_on_vertical_axis
      "top:#{d[:top].to_i + d[:height].to_i - 18}px;left:#{d[:left].to_i + 1}px;width:#{d[:width].to_i}px;height:#{default_size}px;"
    else
      "top:#{d[:top].to_i + 1}px;left:#{d[:left].to_i + d[:width] - default_size - 2}px;width:10px;height:#{d[:height].to_i}px;"
    end
  end


  private
  
  def seconds_to_hours(seconds)
    seconds / 60 / 60
  end


end
