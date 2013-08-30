##### API change #####
# This stuff should be rewritten as a module to 
# be included into Conference.rb.
#
# This is because in multi-conference, all date
# data should reside in the Conference object.
#
# All objects in Ponzu should be able to refer to a Conference
# object, we don't mix in

# Generate methods to retrieve a list of dates as configured in application.rb.
#
# == How to configure dates in Ponzu
#
# A social conference system requires that we have date information
# regarding when the conference will be held, when the poster sessions
# when Yorusemi will be held, etc. We use <tt>config.conference_dates</tt> in 
# <tt>config/application.rb</tt> to configure these.
#
# We often use these dates to generate a list of links for each timetable,
# map or meet_up date. It is also used if we need to create
# a menu of possible dates.
#
# Below is a typical configuration;
#
#    # in config/application.rb
#    config.conference_dates = {
#      :time_table => ['28', '29', '30', '31'].map{|day| "2013-5-#{day}"},
#      :poster => ['28', '29', '30', '31'].map{|day| "2013-5-#{day}"},
#      :meet_up => ['27', '28', '29', '30', '31'].map{|day| "2013-5-#{day}"}
#    }
#
# The ConferenceDates module provides methods to retrive this information.
# We have two interfaces. You can use the module methods listed in this
# rdoc, or you can include the ConferenceDates module into a class.
#
# If the ConferenceDates module is included into a class,
# then the methods +#date_strings+, +#dates+ and +#closest_date+ will
# be added as class methods to the includee class, which will
# delegate to the #date_strings_for, #dates_for and #closest_date_for
# methods with the symbol set to the includee class. 
#
# For example, if you include ConferenceDates into a TimeTable class,
# then TimeTable.date_strings will return the values set in application.rb
# as 
#
#     config.conference_dates = {
#       :time_table => ['28', '29', '30', '31'].map{|day| "2013-5-#{day}"}
#     }
#
# In this case, the following methods will be available;
#
# * TimeTable.date_strings
# * TimeTable.dates
# * TimeTable.closest_date
#
module ConferenceDates
  # def self.included(base)
  #   date_type = base.to_s.underscore.to_sym
  #   base.define_singleton_method :date_strings do
  #     ConferenceDates.date_strings_for(date_type)
  #   end
  #   base.define_singleton_method :dates do
  #     ConferenceDates.dates_for(date_type)
  #   end

  #   base.define_singleton_method :closest_date do |date|
  #     ConferenceDates.closest_date_for(self.to_s.underscore.to_sym, date)
  #   end
  # end


  # module_function

  # Return the information originally set in <tt>config/application.rb</tt> as is
  # (which is as an array of strings representing dates in '2012-12-11' format).
  # The +symbol+ argument specified the hash key.
  def date_strings_for(symbol)
    # We use simple_serialize.rb (JSON-based) to store dates. Therefore, the keys are
    # always strings.
    symbol = symbol.to_s
    raise "dates for Conference #{name} have not yet been set." unless dates
    raise "dates for #{symbol} in Conference #{name} have not yet been set." unless dates[symbol]
    dates[symbol]
  end

  # Return the information in <tt>config/application.rb</tt> after parsing the
  # strings to dates (with Time.zone.parse).
  def dates_for(symbol)
    date_strings_for(symbol).map{|date_string| Time.zone.parse(date_string)}
  end

  # Returns the closest date within the configured dates to the date
  # supplied in the argument. This is useful when you want to automatically
  # change the default timetable page based on today's date.
  def closest_date_for(symbol, date)
    my_date = date.beginning_of_day
    dates = dates_for(symbol)
    if dates.include?(my_date)
      return my_date
    else
      my_date < dates.min ?
        dates.min :
        dates.max
    end
  end
end