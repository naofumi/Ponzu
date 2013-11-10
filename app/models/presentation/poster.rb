# Look at the documentation on Session::Mappable to see how
# display Mappable presentations on the dynamic map.
class Presentation::Poster < Presentation::Mappable
  include ConferenceDates

end