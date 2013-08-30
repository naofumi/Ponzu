# Look at the documentation on Session::Mappable to see how we
# display Mappable presentations on the dynamic map.
#
# === Calculate map coordinates
#
# This can be quite complicated. I'll illustrate the steps below.
#
# First we have to convert ids or numbers/names to map grids.
# For example, we have to convert "1P-032" to a grid location.
# Similarly, for the Exhibition, each booth will be given a Booth number.
# We have to get a grid from that number as well. If a booth is big,
# it may span several grids.
#
# For the poster presentations, converting numbers to coordinates is usually
# quite simple, and only requires a few equations. However, for the Exhibition,
# the assignment might be irregular, in which case we would have to look up
# coordinates from the ActiveRecord objects for each Exhibition.
#
# Therefore this calculation should be the responsibility of each Presentation
# object or Session object (which should be subclasses of Mappable objects).
#
# This mixin adds number to grid calculation to Presentation::Poster objects.
# 
# For Exhibitions, we will probably store the grid objects, serialized in a field.
#
# This conversion takes into account the row
# directions and offsets.
#
module PosterNumberToGrid
end