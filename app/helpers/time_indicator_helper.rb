# encoding: utf-8
module TimeIndicatorHelper
  # Displays the time in a list in the way that 
  # iMessages displays it. That is, instead of 
  # displaying the time for each message,
  # iMessages only displays the time when it is significant.
  #
  # To use #time_in_list_for, pass in the message obj as +obj+.
  #
  # Time indicators are displayed differently depending on whether
  # the messages are in ascending or descending order. This method
  # attempts to automatically detect the order. It uses the time
  # difference of the first two messages with different times.
  #
  # This hasn't been tested much.
  #
  # === list of options
  #
  # class::
  #   The css class for the DIV that will wrap the time string.
  #   Default is 'time_indicator'
  # method::
  #   The method on +obj+ that returns the time to display.
  #   Default is 'created_at'
  # interval::
  #   If the time between consecutive messages is larger than
  #   this interval (in minutes), then display the time indicator.
  #   Default is 15 minutes.
  # format::
  #   The i18n format used to display the time. Default is :month_day_time
  # === Usage (HAML)
  #
  #   - @receipts.each do |r|
  #     = time_in_list_for r
  #     %div
  #       = r.message.body
  #
  def time_in_list_for(obj, options = {})
    @time_cursor ||= nil
    class_name = options[:class] || 'time_indicator'
    time_method = options[:method] || 'created_at'
    interval = options[:interval] || 15
    format = options[:format] || :month_day_time

    time = obj.send(time_method.to_sym)

    if @last_time && @last_time != time
      # If this is not the first call to #time_in_list_for
      # we can autodetect.
      @order = @last_time < time ? :asc : :desc
    else
      # If this is the first call to #time_in_list_for
      # we can't autodetect.
      @order = :desc
    end

    result = if !@time_cursor || 
                (@last_time - time).abs > 60 * interval
      # @time_cursor = time.change(:min => 00)
      @time_cursor = time
      content_tag(:div, l(@time_cursor, :format => format), :class => class_name)
    elsif oclock_change_time = _oclock_change_indicator(@time_cursor, time, @order)
      @time_cursor = oclock_change_time
      content_tag(:div, l(@time_cursor, :format => format), :class => class_name)      
    else
      nil
    end
    @last_time = time
    result
  end

  def _oclock_change_indicator(time_cursor, time, order) #:doc:
    if order == :desc
      # Result should be like:
      # message for 16:03
      # indicator displays 16:00
      # message for 15:55
      # message for 15:30
      #
      # Hence the indicator #hour should be +1 the current time#hour.
      # Also the (indicator - 1sec)#hour should be the same as
      # current message time#hour
      if (time_cursor - 1).hour != time.hour
        time.change(:min => 0, :sec => 0).since(1.hour)
      else
        nil
      end
    elsif order == :asc
      if time_cursor.hour != time.hour
        time.change(:min => 0, :sec => 0)
      else
        nil
      end      
    else
      raise "order parameter must be :desc or :asc"
    end
  end
end
