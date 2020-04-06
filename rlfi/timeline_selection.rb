class TimelineSelection
  attr_reader :selection, :segments
  attr_accessor :index, :segment_width, :synthetic_width

  def initialize index, selection, segment_width, segments = [], drum = false
    @index, @selection, @segment_width, @segments, @drum =
      index, selection, segment_width, segments, drum
  end

  def drum?
    @drum
  end

  def base?
    @index == 0
  end
end
