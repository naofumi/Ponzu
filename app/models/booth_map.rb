# Subclass and implement
#
# +regions+ : 
#    Returns a hash that maps coordinates (left, top, right, bottom) to a list
#    of booth numbers. Used to create clickable areas on the map which
#    will link to a list of the booths.
# +marker+ :
#    Returns a hash that maps booth numbers to coordinates (left, top). Used to display
#    markers for the booths that you liked.
# +marker_size+ :
#    Returns the size of the marker to be displayed on the map.
class BoothMap
  def regions
    raise "Implement in subclass"
  end

  def coordinates_for_booth(booth)
    booth_num = booth.booth_num
    center = marker[booth_num] or raise "Coordinates for booth #{booth_num} not set in #{self.class}"
    center_left = center[0]
    center_top = center[1]
    left = center_left - marker_size/2
    top = center_top - marker_size/2
    return [left, top, marker_size, marker_size]
  end
end