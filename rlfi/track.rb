require "gosu"
require "ruby-audio"
require "securerandom"
require_relative "rms"
require_relative "slider"
require_relative "speed"
require_relative "delay"
require_relative "play_button"
require_relative "writer"
require_relative "player"
require_relative "leveler"
require_relative "volume"
require_relative "button"

class Track
  attr_reader :buffer, :selection_buffer, :modified_selection_buffer, :sample_rate, :channels, :format,
              :filepath, :filename, :tag

  attr_accessor :y, :height
  
  TRACK_HEIGHT = 40

  def initialize filepath, x, y, width, height, prime = false, tag = nil
    @uuid = SecureRandom.uuid
    @filepath = filepath
    @filename = filepath.split("/").last
    @x = x
    @y = y
    @height = height
    @width = width
    @selecting = false
    @prime = prime
    @tag = tag
    @track_width = width - 20
    @zoomed = false
    @read = false

    reset_effects

    @effect_width = width / 10

    x = @x - 20

    @speed_text = Gosu::Image.from_text "spd", 16
    @speed_slider = Slider.new x + @effect_width, @y + TRACK_HEIGHT, @effect_width, 0, 2, @speed
    @speed_slider.on_change do |value|
      if @speed > 0
        @speed = value
        @changed = true
        process_effects
      end
    end

    @delay_text = Gosu::Image.from_text "dly", 16
    @delay_slider = Slider.new x + @effect_width * 3, @y + TRACK_HEIGHT, @effect_width, 0, 3, @delay
    @delay_slider.on_change do |value|
      @delay = value
      @changed = true
      process_effects
    end

    @decay_text = Gosu::Image.from_text "dcy", 16
    @decay_slider = Slider.new x + @effect_width * 5, @y + TRACK_HEIGHT, @effect_width, 0, 3, @decay
    @decay_slider.on_change do |value|
      @decay = value
      @changed = true
      process_effects
    end

    @leveler_text = Gosu::Image.from_text "lev", 16
    @leveler_slider = Slider.new x + @effect_width * 7, @y + TRACK_HEIGHT, @effect_width, 0, 5, @level, true, true
    @leveler_slider.on_change do |value|
      @level = value
      @changed = true
      process_effects
    end

    @volume_text = Gosu::Image.from_text "vol", 16
    @volume_slider = Slider.new x + @effect_width * 9, @y + TRACK_HEIGHT, @effect_width, 0, 2, @volume
    @volume_slider.on_change do |value|
      @volume = value
      @changed = true
      process_effects
    end

    @play_button = PlayButton.new @x + @width - 20, @y + TRACK_HEIGHT / 2 - 5, 10, false
    @play_button.on_click do
      @player.toggle if @player
    end

    @add_button = Button.new "+", 0, 0
    @add_button.on_click do
      @selection_callback.call @selection if @selection_callback && @selection && @changed
      @changed = false
    end

    @subelements = [@speed_slider, @delay_slider, @decay_slider, @leveler_slider, @volume_slider, @play_button]
  end

  def read?
    @read
  end

  def y= new_y
    @y = new_y
    @subelements.each { |elem| elem.y = @y + TRACK_HEIGHT }
    @play_button.y = @y + TRACK_HEIGHT / 2 - @play_button.size / 2.0
  end

  def reset_effects
    @speed = 1.0
    @delay = 0.0
    @decay = 0.0
    @level = 0
    @volume = 1.0
  end

  def on_change &block
    @callback = block
  end

  def on_selection &block
    @selection_callback = block
  end

  def toggle_play
    if @player
      @player.toggle 
      @player.playing? ? @play_button.on : @play_button.off
    end
  end

  def nudge side, direction
    if side == :start
      if direction == :outward
        if @start_x && @start_x > @x
          if @start_x - 1 >= @x
            @start_x -= 1
          else
            @start_x = @x
          end
        end
      elsif direction == :inward
        if @start_x && @select_x && @start_x < @select_x && @start_x + 1 < @select_x
          @start_x += 1
        end
      end
    elsif side == :end
      if direction == :inward
        if @start_x && @select_x &&  @select_x > @start_x && @select_x - 1 >= @start_x
          @select_x -= 1
        end
      elsif direction == :outward
        if @select_x && @select_x < @x + @track_width
          if @select_x + 1 <= @x + @track_width
            @select_x += 1
          else
            @select_x = @x + @track_width
          end
        end
      end
    end

    mouse_up nil, nil, true
  end

  def process_effects
    unless @selection_buffer
      @changed = false
      @modified_selection_buffer = nil
      @selection = nil
      @player.stop if @player
      @play_button.enabled = false
      @subelements.delete @add_button
      zoom_out
      @callback.call nil, nil if @callback
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

    if @level && @level > 0
      @modified_selection_buffer =
        Leveler.new(@level).apply @modified_selection_buffer, @sample_rate, @channels
    end

    if @volume && @volume != 1
      @modified_selection_buffer =
        Volume.new(@volume).apply @modified_selection_buffer, @sample_rate, @channels
    end

    Writer.new(
      @modified_selection_buffer,
      @uuid,
      @channels,
      @sample_rate,
      @format
    ).on_write do |path|
      @path = path
      @selection = Selection.new(
        @modified_selection_buffer,
        @path,
        @sample_rate,
        @channels,
        @speed,
        @delay,
        @decay,
        @level,
        @volume
      )
      @subelements.push @add_button
      @player.stop if @player && @player.playing?
      @player = Player.new @path
      @player.on_update do |time|
      end
      @player.on_done do
        @play_button.off
      end
      @play_button.enabled = true
      @callback.call @modified_selection_buffer, @tag if @callback
    end.write
  end

  def contains? x, y
    @x <= x && @x + @width >= x && @y <= y && @y + @height >= y
  end

  def mouse_down x, y
    if @subelement = @subelements.find { |e| e.contains? x, y }
      @subelement.mouse_down x, y
    elsif x >= @x && x <= @x + @track_width && y >= @y && y <= @y + TRACK_HEIGHT
      @selecting = true
      @start_x = x
    end
  end

  def mouse_up x, y, nudging = false
    if (@selecting || nudging) && @start_x && @select_x
      @selecting = false

      if @select_x <= @start_x
        @start_x, @select_x, @selection_buffer, @selection_start_index, @selection_end_index = nil, nil, nil, 0, @buffer.count - 1
        process_effects
      else
        buffer_count = @display_buffer.count

        start_width = @start_x - @x
        select_width = @select_x - @x

        new_selection_start_index = ((start_width.to_f / @track_width) * buffer_count).to_i
        new_selection_end_index = ((select_width.to_f / @track_width) * buffer_count).to_i

        if @selection_start_index && @selection_end_index && @zoomed
          @frames_added_to_start_since_zoom += new_selection_start_index - @selection_start_index
          @frames_added_to_end_since_zoom += new_selection_end_index - @selection_end_index
        end

        @selection_start_index = new_selection_start_index
        @selection_end_index = new_selection_end_index

        @selection_buffer = RubyAudio::Buffer.float @selection_end_index - @selection_start_index + 1, @channels

        (@selection_start_index...@selection_end_index).each.with_index { |i,j|
          @selection_buffer[j] = @display_buffer[i]
        }

        @changed = true

        process_effects
      end
    elsif @subelement && x && y && !nudging
      @subelement.mouse_up x, y
      @subelement = nil
    end
  end

  def mouse_update x, y
    if @selecting
      @select_x = x if x <= @x + @track_width
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
      @display_buffer = @buffer
      @read = true
    end

    @buffer
  end

  def rms
    @rms ||= begin
      return [] unless @buffer
      rms = RMS.new @track_width
      rms.apply @display_buffer, @sample_rate, @channels
    end 
  end

  def zoom_in
    if !@zoomed && @selection_buffer
      b = []

      buff_start = [@selection_start_index - 100000, 0].max
      buff_end = [@selection_end_index + 100000, @buffer.count].min

      (buff_start..buff_end).each.with_index do |i, j|
        b[j] = @buffer[i]
      end

      @display_buffer = b.dup

      buffer_count = @display_buffer.count

      start_diff_percent = (@selection_start_index - buff_start).to_f / buffer_count
      select_diff_percent = (@selection_end_index - buff_start).to_f / buffer_count

      @zoomed_out_selection_start = @selection_start_index
      @zoomed_out_selection_end = @selection_end_index

      @start_x = @x + @track_width * start_diff_percent
      @select_x = @x + @track_width * select_diff_percent

      start_width = @start_x - @x
      select_width = @select_x - @x

      @selection_start_index = ((start_width.to_f / @track_width) * buffer_count).to_i
      @selection_end_index = ((select_width.to_f / @track_width) * buffer_count).to_i

      @frames_added_to_start_since_zoom = 0
      @frames_added_to_end_since_zoom = 0

      @zoomed = true
      @rms = nil
    end
  end

  def zoom_out
    return unless @zoomed

    @display_buffer = @buffer

    @selection_start_index = [@zoomed_out_selection_start + @frames_added_to_start_since_zoom, 0].max
    @selection_end_index = [@zoomed_out_selection_end + @frames_added_to_end_since_zoom, @buffer.count - 1].min

    @start_x = @x + ((@selection_start_index.to_f / @display_buffer.count) * @track_width)
    @select_x = @x + ((@selection_end_index.to_f / @display_buffer.count) * @track_width)

    @zoomed_out_selection_start = nil
    @zoomed_out_selection_end = nil
    @frames_added_to_start_since_zoom = nil
    @frames_added_to_end_since_zoom = nil
    @zoomed = false
    @rms = nil
  end

  def draw
    return unless read?

    if @start_x && @select_x && @select_x - @start_x > 0
      Gosu::draw_rect @start_x, @y, @select_x - @start_x, 40, Gosu::Color::GRAY
      @add_button.x = @select_x
      @add_button.y = @y
      @add_button.draw
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
    @speed_text.draw @x, y, 1, 1, 1, Gosu::Color::BLACK
    @delay_text.draw @x + @effect_width * 2, y, 1, 1, 1, Gosu::Color::BLACK
    @decay_text.draw @x + @effect_width * 4, y, 1, 1, 1, Gosu::Color::BLACK
    @leveler_text.draw @x + @effect_width * 6, y, 1, 1, 1, Gosu::Color::BLACK
    @volume_text.draw @x + @effect_width * 8, y, 1, 1, 1, Gosu::Color::BLACK

    @speed_slider.draw
    @delay_slider.draw
    @decay_slider.draw
    @leveler_slider.draw
    @volume_slider.draw
    @play_button.draw
  end
end
