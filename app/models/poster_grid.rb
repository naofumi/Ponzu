require File.expand_path('../../../lib/range_set', __FILE__)
# Look at the documentation on Session::Mappable to see how we
# display Mappable presentations on the dynamic map.
#
# === Overview of how we calculate map coordinates
#
# Given a set of grids we can calculate the CSS pixel coordinates.
#
# There are several things to consider.
#
# First, we will often be given multiple grids to calculate a single
# block that spans several grids. This is the situation when we
# create a block for a poster session category, and this is also
# what we have to deal with for large booths.
#
# Second, we have to handle how the grids are mapped. For example,
# in the MBSJ2012, the poster space was divided into three groups;
# the top, middle and bottom groups. When a set of grids span these
# groups, we have to divide them up.
#
# Since the Poster and Exhibition might require very different calculations,
# we keep them as separate classes. Although they have a lot in common,
# the grouping will likely be different, hence #is_same_block? and @second_group_offset
# stuff should be kept separate.
#
# The interface should be such that we simply feed a collection of grids into a
# view helper method, and get the CSS string output. We will be using GridMixin#cssify(grids).
# We get the grids from a method on Session::Mappable or Presentation::Mappable.
#
# == PosterGrid
# Converts Grids into x, y CSS pixel coordinates
# for display on the Poster Map or exhibiton map.
#
# It also handles bundling together multiple Grid objects
# into blocks.
#
# == Synopsis
# 
# #cssifiy(grids)::
#   Returns an array of CSS strings which represent the area the grids cover.
#   This method is located in GridMixin#cssify.
#
# == Customization
#
# This object must be customized based on how the poster hall is laid out
# and what the poster hall image file looks like.
#
# Most of the calculations take place in module GridMixin, but we have
# to implment some methods for GridMixin to work. Refer to the documentation
# in GridMixin for details.
class PosterGrid
  include GridMixin

end