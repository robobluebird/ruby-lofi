require "gosu"
require "ruby-audio"
require_relative "rms"
require_relative "slider"
require_relative "speed"
require_relative "delay"

class Track
  attr_reader :buffer, :selection_buffer, :modified_selection_buffer, :sample_rate, :channels, :format
  
  TRACK_HEIGHT = 40

  def initialize filepath, x, y, width, height
    @filepath = filepath
    @x = x
    @y = y
    @height = height
    @width = width
    @selecting = false

    reset_effects

    @effect_width = width / 6

    @speed_text = Gosu::Image.from_text "speed", 16
    @speed_slider = Slider.new @x + @effect_width, @y + TRACK_HEIGHT, @effect_width, 0, 2, @speed
    @speed_slider.on_change do |value|
      if @speed > 0
        @speed = value
        process_effects
      end
    end

    @delay_text = Gosu::Image.from_text "delay", 16
    @delay_slider = Slider.new @x + @effect_width * 3, @y + TRACK_HEIGHT, @effect_width, 0, 3, @delay
    @delay_slider.on_change do |value|
      @delay = value
      process_effects
    end

    @decay_text = Gosu::Image.from_text "decay", 16
    @decay_slider = Slider.new @x + @effect_width * 5, @y + TRACK_HEIGHT, @effect_width, 0, 3, @decay
    @decay_slider.on_change do |value|
      @decay = value
      process_effects
    end

    @subelements = [@speed_slider, @delay_slider, @decay_slider]
  end

  def reset_effects
    @speed = 1.0
    @delay = 0.0
    @decay = 0.0
  end

  def on_change &block
    @callback = block
  end

  def process_effects
    unless @selection_buffer
      @modified_selection_buffer = nil
      return
    end

    @modified_selection_buffer = @selection_buffer.dup

    if @speed > 0 && @speed != 1
      @modified_selection_buffer =
        Speed.new(@speed).apply @modified_selection_buffer, @sample_rate, @channels
    end

    if @delay > 0 && @decay > 0
      @modified_selection_buffer =
        Delay.new(@delay, @decay).apply @modified_selection_buffer, @sample_rate, @channels
    end

    @callback.call @modified_selection_buffer if @callback
  end

  def contains? x, y
    @x <= x && @x + @width >= x && @y <= y && @y + @height >= y
  end

  def mouse_down x, y
    if x >= @x && x <= @x + @width && y >= @y && y <= @y + 40
      @selecting = true
      @start_x = x
    elsif @subelement = @subelements.find { |e| e.contains? x, y }
      @subelement.mouse_down x, y
    end
  end

  def mouse_up x, y
    if @selecting && @start_x && @select_x
      @selecting = false

      if @select_x <= @start_x
        @start_x, @select_x, @selection_buffer = nil, nil, nil
        process_effects
      else
        buffer_count = @buffer.count
        start_index = (((@start_x - @x) / @width) * buffer_count).to_i
        end_index = ((@select_x - @x) / @width * buffer_count).to_i
        @selection_buffer = RubyAudio::Buffer.float end_index - start_index + 1, @channels
        (start_index..end_index).each.with_index { |i,j| @selection_buffer[j] = @buffer[i] }
        process_effects
      end
    elsif @subelement
      @subelement.mouse_up x, y
      @subelement = nil
    end
  end

  def mouse_update x, y
    if @selecting
      @select_x = x
    elsif @subelement
      @subelement.mouse_update x, y
    end
  end

  def read
    RubyAudio::Sound.open @filepath do |sound|
      @channels = 1
      @sample_rate = sound.info.samplerate
      @format = sound.info.format
      @buffer = RubyAudio::Buffer.float sound.info.frames, @channels
      sound.read @buffer
    end

    @buffer
  end

  def rms
    @rms ||= begin
      return [] unless @buffer
      rms = RMS.new @width
      rms.apply @buffer, @sample_rate, @channels
    end 
  end

  def draw
    if @start_x && @select_x && @select_x - @start_x > 0
      Gosu::draw_rect @start_x, @y, @select_x - @start_x, 40, Gosu::Color::GRAY
    end

		h = TRACK_HEIGHT / 2
    rms.each.with_index do |r, i|
      max = r[1] * h
      min = r[2].abs * h
      rms = r[0] * h
      Gosu::draw_rect @x + i, @y + h - max, 1, max, Gosu::Color::BLUE
      Gosu::draw_rect @x + i, @y + h, 1, min, Gosu::Color::BLUE
      Gosu::draw_rect @x + i, @y + h - rms, 1, rms * 2, Gosu::Color::GREEN
    end

    y = @y + TRACK_HEIGHT

    # x, y, z, scale_x, scale_y, color
    @speed_text.draw @x + @effect_width - @speed_text.width - 20, y, 1, 1, 1, Gosu::Color::BLACK
    @delay_text.draw @x + @effect_width * 3 - @delay_text.width - 20, y, 1, 1, 1, Gosu::Color::BLACK
    @decay_text.draw @x + @effect_width * 5 - @decay_text.width - 20, y, 1, 1, 1, Gosu::Color::BLACK

    @speed_slider.draw
    @delay_slider.draw
    @decay_slider.draw
  end
end
