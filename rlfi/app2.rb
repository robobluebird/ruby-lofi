require "gosu"
require_relative "checkbox"
require_relative "slider"
require_relative "track"

class Lofi < Gosu::Window
  def initialize
    super 640, 480

    self.caption = "ruby lofi"

    @files = ARGV
    @font = Gosu::Font.new self, Gosu::default_font_name, 20
    @elements = tracks
    @mouse_down = false
  end

  def tracks
    @tracks ||= begin
      y = 0
      @files.map do |filepath|
        track = Track.new filepath, 20, y, 600, 60
        track.read
        y += 60
        track.on_change do |buffer|
          puts buffer
        end
        track
      end
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

    # x, y, z, angle, center_x, center_y, scale_x, scale_y, color
    @r.draw_rot width / 2, height / 2, 1, 0, 0.5, 0.5, 1, 1, Gosu::Color::BLACK

    tracks.each(&:draw)
    tracks.each do |track|
      if track.selection_buffer
        # draw sequencer for track
      end
    end
  end

  def needs_cursor?
    true
  end
end

Lofi.new.show
