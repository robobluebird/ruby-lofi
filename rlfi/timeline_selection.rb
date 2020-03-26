class TimelineSelection
  attr_reader :selection, :segments
  attr_accessor :base, :index, :segment_width

  def initialize base, index, selection, segment_width, segments = []
    @base, @index, @selection, @segment_width, @segments =
      base, index, selection, segment_width, segments
  end

  def base?
    @base
  end
end
