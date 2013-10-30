# This holds information for each Room at the venue.
#
# In addition to containing the names and links to map images, it
# also contains pin coordinates so that we can pin-point the location
# using a pin-image.
class Room < ActiveRecord::Base
  attr_accessible :jp_name, :en_name, :jp_location, 
                  :en_location, :map_url, :pin_top, :pin_left
  locale_selective_reader :name, :en => :en_name, :ja => :jp_name
  locale_selective_reader :location, :en => :en_location, :ja => :jp_location
  validates_presence_of :en_name
  acts_as_list

  include ConferenceRefer

  def number
  	name =~ /(\d+)/
  	$1
  end

end
