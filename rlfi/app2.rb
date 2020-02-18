require "gosu"
require_relative "checkbox"
require_relative "slider"
require_relative "track"

class Lofi < Gosu::Window
  def initialize
    super 640, 480

    self.caption = "ruby lofi"

    @files = ARGV
    @prime_checks = []
    @mouse_down = false
    @elements = tracks.dup
    @elements.concat @prime_checks
  end

  def deprime
    @tracks.each do |t|
      t.prime = false
    end
  end

  def decheck tag
    @prime_checks.each { |c| c.set_checked c.tag == tag, false }
  end

  def tracks
    @tracks ||= begin
      y = 0

      @files.map.with_index do |filepath, i|
        track = Track.new filepath, 30, y, 610, 80, y == 0, i
        track.read

        track.on_change do |buffer, pattern|
          puts buffer, pattern
        end

        c = Checkbox.new 10, y + 15, 10, i == 0, i, true, 1, false
        c.on_change do |checked, tag|
          if checked
            deprime
            decheck tag
            track.prime = true

            ty = 0
            @tracks.each.with_index do |t, ti|
              t.y = ty
              @prime_checks[ti].y = ty + 15
              ty += t.height
            end
          end
        end

        @prime_checks << c

        y += 80

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

    # @r = Gosu::Image.from_text "what the...", 20

    # x, y, z, angle, center_x, center_y, scale_x, scale_y, color
    # @r.draw_rot width / 2, height / 2, 1, 0, 0.5, 0.5, 1, 1, Gosu::Color::BLACK

    tracks.each(&:draw)
    @prime_checks.each(&:draw)

    y = tracks.count * tracks.first.height

    tracks.each do |track|
      if track.modified_selection_buffer
        t = Gosu::Image.from_text track.filename, 20
        t.draw 0, y, 1, 1, 1, Gosu::Color::BLACK
        y += t.height
      end
    end
  end

  def needs_cursor?
    true
  end

=begin
@beat = Composer.new
@beat.measures_per_sample = 1
@beat.samples_per_loop = 1
@beat.loops = 4
@beat.set_base path
@beat.set_pattern tag, instrument, steps
@beat.swing = status
@path = @beat.write
=end

end

Lofi.new.show
