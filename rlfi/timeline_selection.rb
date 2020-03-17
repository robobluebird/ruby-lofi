class TimelineSelection
  attr_reader :selection, :segment_width, :segments
  attr_accessor :base, :index

  def initialize base, index, selection, segment_width, segments = []
    @base, @index, @selection, @segment_width, @segments =
      base, index, selection, segment_width, segments
  end

  def base?
    @base
  end
end
