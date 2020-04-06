class Builder
  def initialize name, timeline_selections = [], channels = 1, sample_rate = 44100, format = 65538, buffer = nil
    @timeline_selections = timeline_selections
    @name = name || SecureRandom.uuid
    @channels = channels
    @sample_rate = sample_rate
    @format = format
    @measures = 4
    @frame_count = base.selection.buffer.count * @measures

    if buffer
      @buffer = buffer
    else
      @buffer = RubyAudio::Buffer.float @frame_count, @channels

      i = 0
      while i < @frame_count do
        @buffer[i] = 0.0
        i += 1
      end
    end
  end

  def on_write &block
    @callback = block
  end

  def base
    @base ||= @timeline_selections.find { |ts| ts.base? }
  end

  def build
    @timeline_selections.select { |ts| !ts.drum? && !ts.synthetic_width }.each do |ts|
      ts.segments.each do |ss|
        ss.indicies.each.with_index do |i, j|
          @buffer[i] += ts.selection.buffer[j]

          if @buffer[i] <= -1.0
            @buffer[i] = -0.99
          elsif @buffer[i] >= 1.0
            @buffer[i] = 0.99 
          end
        end
      end
    end

    @timeline_selections.select { |ts| ts.synthetic_width }.each do |ts|
      ts.segments.each do |ss|
        start_index = ss.indicies # this is a Number, not a Range
        
        @timeline_selections.select { |ts| ts.drum? }.each do |dts|
          dts.segments.each do |dss|
            dss.indicies.each.with_index do |i, j|
              offset_index = start_index + i

              @buffer[offset_index] += dts.selection.buffer[j]

              if @buffer[offset_index] <= -1.0
                @buffer[offset_index] = -0.99
              elsif @buffer[offset_index] >= 1.0
                @buffer[offset_index] = 0.99 
              end
            end
          end
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
