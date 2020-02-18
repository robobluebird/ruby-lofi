class Blender
  def initialize buffer, sr, ch, f, mps, loops
    @buffer_count = buffer.count
    @buffer = RubyAudio::Buffer.float @buffer_count * loops, ch
    @samples = []

    loops.times do |loop_index|
      buffer.each.with_index do |frame, index|
        offset = loop_index * @buffer_count
        @buffer[offset + index] = frame
      end
    end

    @ref_buffer = @buffer.dup
    @full_buffer_count = @ref_buffer.count

    @measures_per_sample = mps
    @loops = loops
    @sample_rate = sr
    @channels = ch
    @format = f
  end

  def add_sample buffer, beat
    @samples << [buffer, beat]

    build
  end

  def build
    frames_per_16th = @buffer_count / 16
    @buffer = @ref_buffer.dup

    @loops.times do |loop_index|
      offset = loop_index * @buffer_count

      @samples.each do |s|
        buffer, beat = s

        beat.each do |step|
          frame_index = (step - 1) * frames_per_16th + offset 

          buffer.each do |frame|
            break if frame_index > @full_buffer_count - 1

            new_frame_value = @buffer[frame_index] + frame
            new_frame_value = 1.0 if new_frame_value > 1.0
            new_frame_value = -1.0 if new_frame_value < -1.0

            @buffer[frame_index] = new_frame_value

            frame_index += 1
          end
        end
      end
    end
  end

  def write outpath
    info = RubyAudio::SoundInfo.new(
      channels: @channels,
      samplerate: @sample_rate,
      format: @format
    )

    out = RubyAudio::Sound.open outpath, "w", info

    out.write @buffer

    out.close

    outpath
  end
end
