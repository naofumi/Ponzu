# Look at the documentation on Session::Mappable to see how we
# display Mappable presentations on the dynamic map.
class PosterGrid::GenericConference < PosterGrid

  # Sort grids so to facilitate combining of Grids inside
  # #blockify.
  def sort_grids(grids)
    grids.sort_by {|g| [g.group, g.y, g.x]}
  end

  def initialize
    @slot_width = 15.3
    @slot_height = 15.3
    @origin_x = 42
    @origin_y = 77 - @slot_height
    @first_group_major_groove = 51
    @second_group_major_groove = 45
    @third_group_major_groove = 45
    @minor_groove = 21
    @second_group_origin_y = 291 - @slot_height
    @third_group_origin_y = 448 - @slot_height
    @horizontal_spacing = 31
    @lba_slot_width = 11.8
    @lba_x_offset = 9
  end

  # Return dimensions of a single grid.
  def dimensionify_single(grid)
    col = grid.x
    row = grid.y
    group = grid.group
    slot_width = group == 6 ? @lba_slot_width : @slot_width
    if group == 1
      left = 91 + 216 + col * slot_width + col.div(6) * @horizontal_spacing + @origin_x
    elsif group == 2
      left = 91 + 123 + col.div(5) * @horizontal_spacing + col * slot_width + @origin_x
    elsif group == 3
      left = col * slot_width + @origin_x
    elsif group == 4 || group == 5
      left = 108 + col.div(5) * @horizontal_spacing + col * slot_width + @origin_x
    elsif group == 6
      left = col * slot_width + @lba_x_offset + @origin_x
    else
      raise "bad group"
    end

    if group == 4 || group == 5 || group == 6
      row_offset = group == 4 ? 4 : 0
      o_row = row + row_offset
      top = o_row.div(2) * @first_group_major_groove + o_row.modulo(2) * @minor_groove + @origin_y
    elsif
      group == 1 || group == 2 || group == 3
      row_offset = group == 1 ? 2 : 0
      o_row = row + row_offset
      if 0 <= o_row && o_row <= 3
        top = o_row.div(2) * @second_group_major_groove + o_row.modulo(2) * @minor_groove + @second_group_origin_y
      elsif 4 <= o_row && o_row <= 7
        top = (o_row - 4).div(2) * @third_group_major_groove + (o_row - 4).modulo(2) * @minor_groove + @third_group_origin_y
      end
    else
      raise "bad group"
    end

    Dimension.new(left, top, left + slot_width, top + @slot_height, @slot_height, slot_width)
  end

  def is_same_block?(grid_1, grid_2)
    return true if !grid_1 || !grid_2
    if grid_1.group == 1
      range_set = RangeSet.new(0..5, 6..10)
    elsif grid_1.group == 2
      range_set = RangeSet.new(0..4, 5..9, 10..14)
    elsif grid_1.group == 3
      range_set = RangeSet.new(0..5)
    elsif grid_1.group == 4
      range_set = RangeSet.new(0..4, 5..9, 10..14, 15..19)
    elsif grid_1.group == 5
      range_set = RangeSet.new(0..4, 5..9, 10..14, 15..19, 20..24)
    elsif grid_1.group == 6
      range_set = RangeSet.new(0..4)
    else
      raise "SHIT"
    end
    grid_1.group == grid_2.group && grid_1.y == grid_2.y && range_set.same_range?(grid_1.x, grid_2.x)
  end

  def labels
    result = []
    # 0.upto(11).each{|i|
    #   top = @origin_y
    #   left_1 = i * @even_col_spacing + @origin_x
    #   left_2 = i * @odd_col_spacing + @odd_col_offset  + @origin_x
    #   [0, @second_group_offset, @third_group_offset].each do |top_offset|
    #     result += [[i, "top:#{top + top_offset}px;left:#{left_1}px;"], 
    #                [i, "top:#{top + top_offset + 20}px;left:#{left_2}px;color:green"]]
    #   end
    # }
    result
  end

end