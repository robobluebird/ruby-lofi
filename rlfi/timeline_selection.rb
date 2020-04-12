class TimelineSelection
  attr_reader :selection
  attr_accessor :index, :segments, :segment_width, :synthetic_width

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
