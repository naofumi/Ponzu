# Look at the documentation on Session::Mappable to see how
# display Mappable presentations on the dynamic map.
class Presentation::Poster < Presentation::Mappable
  include ConferenceDates
#  after_initialize :set_poster_grid

  # Delegate :poster, :grid, :grids to the conference specific
  # PosterNumberToGrid::#{conference.module_name}
  #
  # To get the the Conference object efficiently, we rely on the
  # :inverse_of declarations in the accessors (without going to the DB). 
  # We initially tried doing a Module#include at the :after_initialize
  # callback, but the :inverse_of declarations are not effective yet.
  #
  # Therefore, we decided to evaluate PosterNumberToGrid::#{conference.module_name}
  # after the delegate methods were called.
  delegate :poster_slot, :grid, :grids, :to => :poster_number_to_grid_delegate

  private

  def poster_number_to_grid_delegate
    "PosterNumberToGrid::#{conference.module_name}".constantize.new(self)
  end

end