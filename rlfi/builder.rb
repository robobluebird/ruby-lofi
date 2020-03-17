class Builder
  def initialize name, timeline_selections = [], channels = 1, sample_rate = 44100, format = 65538
    @timeline_selections = timeline_selections
    @name = name || SecureRandom.uuid
    @channels = channels
    @sample_rate = sample_rate
    @format = format
    @measures = 16
    @frame_count = base.selection.buffer.count * @measures
    @buffer = RubyAudio::Buffer.float @frame_count, @channels
    i = 0
    while i < @frame_count do
      @buffer[i] = 0.0
      i += 1
    end
  end

  def on_write &block
    @callback = block
  end

  def base
    @base ||= @timeline_selections.find { |ts| ts.base? }
  end

  def build
    @timeline_selections.sort_by { |s| s.index }.each do |ts|
      ts.segments.each do |ss|
        ss.indicies.each.with_index do |i, j|
          @buffer[i] += ts.selection.buffer[j]
          @buffer[i] <= -1.0 ? @buffer[i] = -0.99 : @buffer[i] = 0.99 if @buffer[i] >= 1.0
        end
      end
    end
  end

  def write
    Writer.new(
      @buffer,
      @name,
      @channels,
      @sample_rate,
      @format
    ).on_write do |path|
      @callback.call path if @callback
    end.write
  end
end
