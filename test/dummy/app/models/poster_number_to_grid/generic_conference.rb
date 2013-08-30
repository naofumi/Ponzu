# Look at the documentation on Session::Mappable to see how we
# display Mappable presentations on the dynamic map.
module PosterNumberToGrid
  class GenericConference < PosterNumberToGrid::Base

    def poster_slot
      @presentation.position.to_i + 1
      # number =~ /(?:P)-(\d+)/
      # $1.to_i
    end

    # We convert the poster slot number to a grid coordinate.
    def grid
      if 1 <= poster_slot && poster_slot <= 66
        offset = 1
        number_per_row = 11
        total_rows = 6
        group = 1
        row = total_rows - 1 - (poster_slot - offset).div(number_per_row)
        col = (poster_slot - offset).modulo(number_per_row)
        col = number_per_row - 1 - col if row.even? # invert
      elsif 67 <= poster_slot && poster_slot <= 96
        offset = 67
        number_per_row = 15
        group = 2
        total_rows = 2
        row = total_rows - 1 - (poster_slot - offset).div(number_per_row)
        col = (poster_slot - offset).modulo(number_per_row)
        col = number_per_row - 1 - col if row.even? # invert
      elsif 97 <= poster_slot && poster_slot <= 144
        offset = 97
        number_per_row = 6
        group = 3
        total_rows = 8
        row = total_rows - 1 - (poster_slot - offset).div(number_per_row)
        col = (poster_slot - offset).modulo(number_per_row)
        col = number_per_row - 1 - col if row.odd? # invert
      elsif 145 <= poster_slot && poster_slot <= 184
        offset = 145
        number_per_row = 20
        group = 4
        total_rows = 2
        row = total_rows - 1 - (poster_slot - offset).div(number_per_row)
        col = (poster_slot - offset).modulo(number_per_row)
        col = number_per_row - 1 - col if row.even? # invert
      elsif 185 <= poster_slot && poster_slot <= 284
        offset = 185
        number_per_row = 25
        group = 5
        total_rows = 4
        row = total_rows - 1 - (poster_slot - offset).div(number_per_row)
        col = (poster_slot - offset).modulo(number_per_row)
        col = number_per_row - 1 - col if row.even? # invert
      elsif 285 <= poster_slot && poster_slot <= 314
        offset = 285
        number_per_row = 5
        group = 6
        total_rows = 6
        row = (poster_slot - offset).div(number_per_row)
        col = (poster_slot - offset).modulo(number_per_row)
        col = number_per_row - 1 - col if row.even? # invert
      else
        return nil
      end
      Grid.new(col, row, group)
    end

    # Presentation::Mappable objects are required to implement
    # #grids
    def grids
      [grid].compact
    end
  end
end
