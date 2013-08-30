# Include this mixin into PosterGrid or ExhibitionGrid
# to enable calculation of CSS strings from an array of Grids.
#
# PosterGrid or ExhibitionGrid (the includees) must provide 
# the following methods to acquire the methods provided by GridMixIn.
#
# <tt>is_same_block?(grid_1, grid_2)</tt>::
#   This must tell us whether two Grid objects should be included into
#   a single block. This depends on how the grid is divided into groups.
#   For example, in the MBSJ, the poster hall grid was divided into 
#   top, middle and bottom groups.
#
# <tt>dimensionify_single(grid)</tt>::
#   This returns the dimensions of single Grid object as a Dimension object.
#   This depends on the whole layout.
module GridMixin
  Dimension = Struct.new(:left, :top, :right, :bottom, :height, :width) do
    def to_css
      "left:#{left}px;top:#{top}px;height:#{height}px;width:#{width}px"
    end
  end

  # Converts an array of Grid objects into a set of Dimension objects
  # which represent the area which the Grid objects cover.
  def dimensionify(grids)
    blocks = blockify(grids)
    blocks.inject([]) do |memo, block|
      memo << dimensionify_multiple(block)
    end.compact
  end

  # Converts an array of Grid objects into a set of CSS strings
  # which represent the area which the Grid objects cover.
  def cssify(grids)
    dimensionify(grids).map{|d| d.to_css}
  end

  # Generate continuous blocks from grids.
  # Non-consecutive grids will be separated.
  #
  # This is because we are working one block at a time.
  #
  # Blocks are represented as an array of Grid objects.
  #
  # Takes a flat array of Grid objects as an argument
  # and returns an array of array of Grid objects.
  def blockify(grids)
    result = []
    current_block = []
    grids = sort_grids(grids)
    grids.each do |grid|
      if is_consecutive?(current_block.last , grid) &&
         is_same_block?(current_block.last, grid)
        current_block << grid
      else
        result << current_block
        current_block = [grid]
      end
    end
    result << current_block
    result
  end

  # Sort grids so to facilitate combining of Grids inside
  # #blockify.
  def sort_grids(grids)
    grids.dup.sort_by{|g| [g.group, g.y, g.x]}
  end

  # Test if two Grid objects are consecutive.
  # We test here based on distance.
  def is_consecutive?(grid_1, grid_2)
    return true if !grid_1 || !grid_2
    (grid_1.x - grid_2.x)**2 + (grid_1.y - grid_2.y)**2 <= 1
  end

  # Assume squarish and blockifed set of grids
  def dimensionify_multiple(grids)
    return nil if grids.empty?
    top, bottom, left, right = nil, nil, nil, nil
    grids.each do |grid|
      location = dimensionify_single(grid)
      top ||= location.top
      top = location.top if location.top < top
      left ||= location.left
      left = location.left if location.left < left
      right ||= location.right
      right = location.right if location.right > right
      bottom ||= location.bottom
      bottom = location.bottom if location.bottom > bottom
    end
    Dimension.new(left, top, right, bottom, bottom - top, right - left)
  end

end