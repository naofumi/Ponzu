# Grid objects are simple structures with
# only x, y coordinates.  Top-left is x:0, y:0.
#
# We use them as intermediates when calculating
# pixel coordinates from Poster numbers.
#
# Grid objects are generated from Presentation::Mappable
# objects (and also via Session::Mappable#grids which calls
# Presentation::Mappable#grid). Eveery Presenation::Mappable
# object must implement a Presentation::Mappable#grids method
# which returns an array of Grid objects.
class Grid < Struct.new(:x, :y, :group)
  def initialize(x, y, group = 0)
    super(x, y, group)
  end
end
