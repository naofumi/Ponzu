require 'test_helper'
require_relative '../../lib/range_set'

class RangeSetTest < ActiveSupport::TestCase
  def setup
    @range_set = RangeSet.new((1..4), (6..8), (10..12))
  end

  def test_value_detection
    assert_equal (1..4), @range_set.range_covering_value(2)
    assert_equal 0, @range_set.range_index_for_value(2)
    assert_equal (6..8), @range_set.range_covering_value(8)
    assert_equal 1, @range_set.range_index_for_value(8)
    assert_equal (10..12), @range_set.range_covering_value(11)
    assert_equal 2, @range_set.range_index_for_value(11)
  end
  
  def test_position
    assert_equal (10..12), @range_set.position(11).range
    assert_equal 2, @range_set.position(11).range_index
    assert_equal 1, @range_set.position(11).left
  end

  def test_position_out_of_range
    assert_nil @range_set.position(13)
    assert_nil @range_set.position(5)
  end

  def test_as_enumerable
    assert_equal 3, @range_set.count
  end

  def test_same_range?
    assert @range_set.same_range?(2, 3)
    assert @range_set.same_range?(1, 2, 3)
    refute @range_set.same_range?(1, 7)
    refute @range_set.same_range?(1, 7, 10)
  end
end

