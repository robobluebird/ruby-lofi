require "gosu"
require "fileutils"
require_relative "checkbox"
require_relative "slider"
require_relative "track"
require_relative "selection"
require_relative "timeline"
require_relative "builder"

class Lofi < Gosu::Window
  def initialize
    super 640, 480

    self.caption = "ruby lofi"

    track_name = "#{SecureRandom.uuid}.wav"

    @play_button = PlayButton.new width / 2 - 10, height - 20, 20, false

    @play_button.on_click do
      @player.toggle if @player
    end

    @files = ARGV
    @prime_checks = []
    @mouse_down = false
    @elements = tracks.dup
    @elements.concat @prime_checks
    @selections = []
    @measures = 4

    @timeline = Timeline.new 0, 0, width

    @timeline.on_recalculate do |measures, timeline_selections, base_buffer_count|
      @measures = measures

      t = tracks.first

      @frame_count = base_buffer_count * @measures
      @buffer = RubyAudio::Buffer.float @frame_count, t.channels
      i = 0
      while i < @frame_count do
        @buffer[i] = 0.0
        i += 1
      end

      b = Builder.new track_name, timeline_selections, t.channels, t.sample_rate, t.format, @buffer.dup
      b.on_write do |path|
        @path = path
        @player = Player.new @path

        @player.on_update do |time|
        end

        @player.on_done do
          @play_button.off
        end

        @play_button.enabled = true
        @most_recently_edited_timeline = true
        @most_recent_track_selection_tag = nil
      end

      b.build
      b.write
    end

    @timeline.on_change do |timeline_selections, base_buffer_count|
      t = tracks.first

      if !@buffer
        @frame_count = base_buffer_count * @measures
        @buffer = RubyAudio::Buffer.float @frame_count, t.channels
        i = 0
        while i < @frame_count do
          @buffer[i] = 0.0
          i += 1
        end
      end

      b = Builder.new track_name, timeline_selections, t.channels, t.sample_rate, t.format, @buffer.dup
      b.on_write do |path|
        @path = path
        @player = Player.new @path

        @player.on_update do |time|
        end

        @player.on_done do
          @play_button.off
        end

        @play_button.enabled = true
        @most_recently_edited_timeline = true
        @most_recent_track_selection_tag = nil
      end

      b.build
      b.write
    end

    @elements.push @timeline
    @elements.push @play_button
  
    @colors = [Gosu::Color::RED, Gosu::Color::GREEN, Gosu::Color::YELLOW, Gosu::Color::BLUE]
    @color_index = 0

    # FileUtils.rm_rf "lofi"
    FileUtils.mkdir "lofi" unless Dir.exists? "lofi"
  end

  def next_color
    @colors[@color_index].tap do
      @color_index += 1
      @color_index = 0 if @color_index >= @colors.count
    end
  end

  def deprime
    @tracks.each do |t|
      t.prime = false
    end
  end

  def track_with_most_recent_selection
    @tracks.find { |t| t.tag == @most_recent_track_selection_tag } if @most_recent_track_selection_tag
  end
  

  def tracks
    @tracks ||= begin
      y = 0

      @files.map.with_index do |filepath, i|
        track = Track.new filepath, 20, y, 620, 80, false, i
        track.read

        track.on_change do |buffer, tag|
          @most_recent_track_selection_tag = tag
          @most_recently_edited_timeline = false
        end

        track.on_selection do |selection|
          @elements.push selection
          @selections.push selection

          selection.deleteable = false
          selection.color = next_color

          selection.on_delete do
            @elements.delete selection
            @selections.delete selection
            @timeline.delete selection
          end

          if @timeline.base?
            @timeline.add_selection selection
          else
            @timeline.add_base selection
          end
        end

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
    elsif (button_down?(Gosu::KB_LEFT) || button_down?(Gosu::KB_H))
      if !@left && track_with_most_recent_selection
        @left, @right = true, false

        if button_down?(Gosu::KB_LEFT_SHIFT) || button_down?(Gosu::KB_RIGHT_SHIFT)
          track_with_most_recent_selection.nudge :start, :inward
        else
          track_with_most_recent_selection.nudge :start, :outward
        end
      end
    elsif @left
      @left = false
    elsif (button_down?(Gosu::KB_RIGHT) || button_down?(Gosu::KB_L))
      if !@right && track_with_most_recent_selection
        @right, @left = true, false

        if button_down?(Gosu::KB_LEFT_SHIFT) || button_down?(Gosu::KB_RIGHT_SHIFT)
          track_with_most_recent_selection.nudge :end, :inward
        else
          track_with_most_recent_selection.nudge :end, :outward
        end
      end
    elsif @right
      @right = false
    elsif button_down? Gosu::KB_SPACE
      if !@space
        @space = true
        if @most_recently_edited_timeline
          @player.toggle if @player
          @player && @player.playing? ? @play_button.on : @play_button.off
        elsif track_with_most_recent_selection
          track_with_most_recent_selection.toggle_play
        end
      end
    elsif @space
      @space = false
    elsif (button_down?(Gosu::KB_UP) || button_down?(Gosu::KB_K))
      if !@up && track_with_most_recent_selection
        @up, @down = true, false
        track_with_most_recent_selection.zoom_in
      end
    elsif @up
      @up = false
    elsif (button_down?(Gosu::KB_DOWN) || button_down?(Gosu::KB_J))
      if !@down && track_with_most_recent_selection
        @down, @up = true, false
        track_with_most_recent_selection.zoom_out
      end
    elsif @down
      @down = false
    end
  end
 
  def draw
    draw_rect 0, 0, width, height, Gosu::Color::WHITE

    @prime_checks.each(&:draw)

    y = 0
    tracks.each do |t|
      t.draw
      y += t.height
    end

    x = 0
    @selections.each do |s|
      s.x = x
      s.y = y
      s.draw

      if x + s.w + 10 > width
        x = 0
        y += s.h
      else
        x += s.w + 10
      end
    end

    if @selections.any?
      y += @selections.last.h unless y > @selections.last.y
    end

    if @timeline.timeline_selections.any?
      @play_button.draw
    end

    @timeline.y = y
    @timeline.draw
  end

  def needs_cursor?
    true
  end
end

Lofi.new.show
