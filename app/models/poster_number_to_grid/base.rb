# Look at the documentation on Session::Mappable to see how we
# display Mappable presentations on the dynamic map.
module PosterNumberToGrid
  class Base
    def initialize(presentation)
      @presentation = presentation
    end

    # We initially designed PosterNumberToGrid::Base as a delegate
    # for the Presentation::Poster object, so that you could call
    # Presentation::Poster#grid to get the grid of that poster. However, this 
    # means that each presentation object is tied to its display
    # as a grid, which causes unflexibility. It also means
    # that a Presentation object has to request the Conference object
    # in order to bind the delegate object to the one that is appropriate
    # for the conference. Requesting the Conference object affects performance.
    #
    # Instead, we now calculate grids from presentations in the view.
    # Using the #current_conference object available in the view, we
    # load the PosterNumberToGrid object using grid_converte(current_conference)
    # which is defined as a helper method. This returns a PosterNumberToGrid::Base subclass.
    # We then use the class methods #presentations_to_grids and #presentation_to_grid
    # to calculate the grids from the presentations.
    #
    def self.presentations_to_grids(presentations)
      presentations.map{|p| self.presentation_to_grid(p)}.flatten.compact
    end

    def self.presentation_to_grid(presentation)
      self.new(presentation).grid
    end
  end
end
