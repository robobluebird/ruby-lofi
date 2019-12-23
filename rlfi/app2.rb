require "gosu"
require "ruby-audio"
require_relative "checkbox"
require_relative "slider"
require_relative "rms"

class Track
  attr_accessor :buffer, :selection_buffer, :sample_rate, :channels, :format

  def initialize filepath, x, y, width, height
    @filepath = filepath
    @x = x
    @y = y
    @height = height
    @width = width
  end

  def contains? x, y
    @x <= x && @x + @width >= x && @y <= y && @y + @height >= y
  end

  def mouse_down x, y
    @start_x = x
  end

  def mouse_up x, y
    if @start_x && @select_x
      if @select_x <= @start_x
        @start_x, @select_x, @selection_buffer = nil, nil, nil
      else
        buffer_count = @buffer.count
        start_index = (((@start_x - @x) / @width) * buffer_count).to_i
        end_index = ((@select_x - @x) / @width * buffer_count).to_i
        @selection_buffer = RubyAudio::Buffer.float end_index - start_index + 1, @channels
        (start_index..end_index).each.with_index { |i,j| @selection_buffer[j] = @buffer[i] }
      end
    end
  end

  def mouse_update x, y
    @select_x = x
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
      Gosu::draw_rect @start_x, @y, @select_x - @start_x, @height, Gosu::Color::GRAY
    end

		h = 20
    rms.each.with_index do |r, i|
      max = r[1] * h
      min = r[2].abs * h
      rms = r[0] * h
      Gosu::draw_rect @x + i, @y + h - max, 1, max, Gosu::Color::BLUE
      Gosu::draw_rect @x + i, @y + h, 1, min, Gosu::Color::BLUE
      Gosu::draw_rect @x + i, @y + h - rms, 1, rms * 2, Gosu::Color::GREEN
    end
  end
end

class Lofi < Gosu::Window
  def initialize
    super 640, 480

    self.caption = "ruby lofi"

    @files = ARGV

    @font = Gosu::Font.new self, Gosu::default_font_name, 20
    @c1 = Checkbox.new width / 4, height / 4, 20, true
    @s1 = Slider.new (width / 4) * 3, (height / 4) * 3, 100, 1, 4, true, true

    @elements = tracks

    @mouse_down = false
  end

  def tracks
    y = 0
    @files.map do |filepath|
      track = Track.new filepath, 40, y, 600, 40
      track.read
      y += 40
      track
    end
  end

  def update
    if button_down? Gosu::MS_LEFT
      if @mouse_down
        down = @elements.find { |e| e.contains? mouse_x, mouse_y }
        down.mouse_update mouse_x, mouse_y if down
      else
        @mouse_down = true
        down = @elements.find { |e| e.contains? mouse_x, mouse_y }
        down.mouse_down mouse_x, mouse_y if down
      end
    elsif @mouse_down
      @mouse_down = false
      up = @elements.find { |e| e.contains? mouse_x, mouse_y }
      up.mouse_up mouse_x, mouse_y if up
    end
  end
 
  def draw
    draw_rect 0, 0, width, height, Gosu::Color::WHITE

    @r = Gosu::Image.from_text "what the...", 20
    @r.draw_rot width / 2, height / 2, 1, 0, 0.5, 0.5, 1, 1, Gosu::Color::BLACK

    @elements.each(&:draw)
  end

  def needs_cursor?
    true
  end
end

Lofi.new.show
