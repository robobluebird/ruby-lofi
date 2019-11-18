class SoundNotLoadedError < StandardError; end
class BadOffsetError < StandardError; end

class Track
  attr_reader :buffer, :main_buffer, :sample_rate, :channels, :start_offset, :end_offset,
              :sample_rate_modifier, :output_filepath

  attr_accessor :delay_rate, :decay_rate, :eq_high, :eq_mid, :eq_low, :fade_dir

  DEFAULT_CHANNELS = 1

  def initialize filepath, output_filename = nil
    @input_filepath = File.expand_path filepath
    @input_filename = @input_filepath.split("/").last
    @main_buffer = nil
    @buffer = nil
    @sample_rate_modifier = 1.0
    @output_filename = output_filename

    @delay_rate = nil
    @decay_rate = nil
    @eq_high = nil
    @eq_mid = nil
    @eq_low = nil
    @fade_dir = nil
  end

  def duration
    @buffer.count.to_f / @sample_rate
  end

  def bpm beat_count
    sample_count = @end_offset - @start_offset
    sample_count = sample_count / @sample_rate_modifier if @sample_rate_modifier != 1.0
    sample_time  = sample_count.to_f / @sample_rate
    seconds_per_beat = sample_time / beat_count
    60.0 / seconds_per_beat
  end

  def read
    RubyAudio::Sound.open @input_filepath do |sound|
      @main_buffer = sound.read :float, sound.info.frames
      @start_offset = 0
      @end_offset = @main_buffer.real_size
      @main_buffer = monoize if sound.info.channels == 2
      @channels = DEFAULT_CHANNELS
      @sample_rate = sound.info.samplerate
      @format = sound.info.format # RubyAudio::FORMAT_PCM_U8 # ??? 
      @buffer = sample
      @output_filename = @output_filename ||
        "#{@input_filename.split(".").first.downcase.gsub(" ", "_")}_ruby_lofi.wav"
      @output_filepath = File.join Dir.pwd, "project", @output_filename
    end

    write

    @buffer.count
  end

  def ready?
    !@buffer.nil?
  end

  def write
    raise SoundNotLoadedError if @main_buffer.nil?

    info = RubyAudio::SoundInfo.new(
      channels: @channels,
      samplerate: @sample_rate,
      format: @format
    )

    out = RubyAudio::Sound.open @output_filepath, "w", info

    buffer = sample

    if @sample_rate_modifier != 1.0
      speed = Speed.new @sample_rate_modifier
      buffer = speed.apply buffer, @sample_rate, @channels
    end

    if @delay_rate && @decay_rate
      delay = Delay.new @delay_rate, @decay_rate
      buffer = delay.apply buffer, @sample_rate, @channels
    end

    if @eq_low && @eq_mid && @eq_high
      eq = EQ.new
      eq.low_gain = @eq_low
      eq.mid_gain = @eq_mid
      eq.high_gain = @eq_high
      buffer = eq.apply buffer, @sample_rate, @channels
    end

    if @fade_dir
      fade = Fade.new @fade_dir
      buffer = fade.apply buffer, @sample_rate, @channels
    end

    norm = Normalize.new
    buffer = norm.apply buffer, @sample_rate, @channels

    rando = Rando.new
    buffer = rando.apply buffer, @sample_rate, @channels

    out.write buffer

    out.close

    @output_filepath
  end

  def sample_rate_modifier= modifier
    @sample_rate_modifier = (modifier || 1).to_f
  end

  def modified_sample_rate
    @sample_rate * @sample_rate_modifier
  end

  def set_percent_offsets start_percent = nil, end_percent = nil
    raise SoundNotLoadedError if @main_buffer.nil?
    raise BadOffsetError if start_percent && end_percent && start_percent >= end_percent

    @start_offset = (start_percent.to_f * @main_buffer.count).floor if start_percent
    @end_offset = (end_percent.to_f * @main_buffer.count).ceil if end_percent

    refocus
  end

  def set_time_offsets start_seconds = nil, end_seconds = nil
    raise SoundNotLoadedError if @main_buffer.nil?

    if start_seconds || end_seconds
      start_seconds = start_seconds.to_f if start_seconds
      end_seconds = end_seconds.to_f if end_seconds

      raise BadOffsetError if start_seconds && end_seconds && start_seconds >= end_seconds

      @start_offset = (start_seconds * @sample_rate).floor if start_seconds
      @end_offset = (end_seconds * @sample_rate).floor if end_seconds

      refocus
    end
  end

  def reset
    raise SoundNotLoadedError if @main_buffer.nil?

    @start_offset, @end_offset = 0, @main_buffer.count

    refocus
  end

  def effect effector
    raise SoundNotLoadedError if @buffer.nil?

    # needs to respond to apply and take a buffer
    @buffer = effector.apply @buffer, @sample_rate, @channels

    # return self for chaining
    self
  end

  def analyze analyzer
    raise SoundNotLoadedError if @buffer.nil?

    analyzer.apply @buffer, @sample_rate, @channels
  end
  
  private

  def monoize
    new_buffer_frame_count = @end_offset - @start_offset
    new_buffer = RubyAudio::Buffer.float new_buffer_frame_count, 1
    new_buffer_index = 0
    old_buffer_index = @start_offset

    while new_buffer_index < new_buffer_frame_count
      new_buffer[new_buffer_index] = @main_buffer[old_buffer_index].reduce(&:+) / 2
      new_buffer_index += 1
      old_buffer_index += 1
    end

    new_buffer
  end

  def sample
    new_buffer_frame_count = @end_offset - @start_offset
    new_buffer = RubyAudio::Buffer.float new_buffer_frame_count, @channels
    new_buffer_index = 0
    old_buffer_index = @start_offset

    while new_buffer_index < new_buffer_frame_count
      new_buffer[new_buffer_index] = @main_buffer[old_buffer_index]
      new_buffer_index += 1
      old_buffer_index += 1
    end

    new_buffer
  end

  def refocus
    @buffer = sample
  end
end
