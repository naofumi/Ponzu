
class RangeSet
  Position = Struct.new(:range, :range_index, :left)

  include Enumerable
  
  def initialize(*ranges)
    @ranges = ranges
  end

  def [](index)
    @ranges[index]
  end
  
  def position(value)
    covering_range = @ranges.detect{|r| r.cover?(value)}
    if covering_range
      Position.new(covering_range, 
                   @ranges.index(covering_range),
                   value - covering_range.begin)
    else
      nil
    end
  end

  def range_covering_value(value)
    p = position(value)
    p ? p.range : nil
  end

  def range_index_for_value(value)
    p = position(value)
    p ? p.range_index : nil
  end

  def same_range?(*args)
    raise "need equal to or more than two ranges for args" if args.size < 2
    first_range = range_covering_value(args.shift)
    !args.detect {|value| first_range != range_covering_value(value)}
  end
    
  def each(&block)
    if defined?(block)
      @ranges.each(&block)
    else
      @ranges.each
    end
  end
  
  def last
    @ranges[@ranges.size - 1]
  end
  
  private
  
end

