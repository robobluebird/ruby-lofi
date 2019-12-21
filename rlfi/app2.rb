require "gosu"
require "ruby-audio"
require_relative "checkbox"
require_relative "slider"

class Track
  attr_accessor :buffer, :sample_rate, :channels, :format

  def initialize filepath
    @filepath = filepath
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
               group_size = @buffer.count / 640
               @buffer.rms group_size
             end 
  end

  def draw
    rms.each.with_index do |r, i|
      max = r[1] * 50
      min = r[2] * 50
      # rms = r[0] * 50
      Gosu::draw_rect i, 50 - max, 2, max, Gosu::Color::BLUE
      Gosu::draw_rect i, 50, 2, min, Gosu::Color::GREEN
      # Gosu::draw_rect i, 50 - (rms / 2), 2, rms, Gosu::Color::GREEN
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

    @elements = [@c1, @s1] + tracks

    @mouse_down = false
  end

  def tracks
    @files.map do |filepath|
      track = Track.new filepath
      track.read
      track
    end
  end

  def update
    if button_down? Gosu::MS_LEFT
      @mouse_down = true
      down = @elements.find { |e| e.contains? mouse_x, mouse_y }
      down.mouse_down mouse_x, mouse_y if down
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
