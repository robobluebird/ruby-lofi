class VisualizedTrack
  attr_reader :x, :y, :width, :height, :track
  attr_accessor :beat_count

  def initialize filepath
    @track = Track.new filepath
    @x = 0
    @y = 0
    @z = 10
    @width = 200
    @height = 50
    @border = nil
    @content = nil
    @highlight = nil
    @rms_tines = []
    @peak_tines = []
    @slice_count = 1000
    @full_width = true
    @highlighting = false
    @selection = nil
    @did_move = false
    @buttons = []
    @path = nil
    @beat_count = 4
    @pid = nil
    @playing = false
    @callback = nil
    @duration_per_tine = nil
    @keys = []
    @start_index = 0
    @end_index = @slice_count - 1
    add
  end

  def on_change &block
    @callback = block
  end

  def effect opts = {}
    opts.each_pair do |key, value|
      method = (key.to_s + "=").to_sym
      @track.send method, value
    end

    write
  end

  def full_width?
    @full_width
  end

  def x= new_x
    diff = new_x - @x
    @x = new_x
    @content.x = new_x
    @border.x = new_x - 2
    @selection.x = @selection.x + diff if @selection
  end

  def y= new_y
    diff = new_y - @y
    @y = new_y
    @content.y = new_y
    @border.y = new_y - 2
    @selection.y = @selection.y + diff if @selection
  end

  def width= new_width
    @width = new_width
    @content.width = new_width
    @border.width = new_width + 4
  end

  def mouse_down x, y
    if content_click x, y
      @highlighting = true

      if @keys.find { |k| k.include? "shift" }
        @end_index = @rms_tines.index do |t|
          t.x <= x && t.x + t.width >= x
        end
        draw_selection true
        set_track_offsets
        @did_move = true
      else
        @start_index = @rms_tines.index do |t|
          t.x <= x && t.x + t.width >= x
        end
      end
    elsif @button_clicked = button_click(x, y)
      @button_clicked.mouse_down x, y
    end
  end

  # def mouse_scroll dx, dy, x, y
  #   if dy > 0 && !@track.zoomed_in?
  #     zoom :in, x
  #   elsif dy < 0 && @track.zoomed_in?
  #     zoom :out
  #   end
  # end

  def key_down key
    @keys.push key
  end

  def key_up key
    @keys.delete key
    
    if ["left", "right"].index key
      return unless @selection

      shifted = @keys.find { |k| k.include? "shift" }

      nudge shifted ? :end : :start, key.to_sym
    end
  end

  def content_click x, y
    @content.x <= x && @content.x + @content.width >= x &&
      @content.y <= y && @content.y + @content.height >= y
  end

  def button_click x, y
    @buttons.find do |button|
      button.x <= x && button.x + button.width >= x &&
        button.y <= y && button.y + button.height >= y
    end
  end

  def mouse_up x, y
    if @highlighting
      @highlighting = false
      draw_selection
      set_track_offsets
      @did_move = false
    elsif @button_clicked
      @button_clicked.mouse_up x, y
      @button_clicked = nil
    end
  end

  def mouse_move x, y
    if @highlighting
      @did_move = true

      @end_index = @rms_tines.index do |t|
        t.x <= x && t.x + t.width >= x
      end || @slice_count - 1

      draw_selection
    end
  end

  def can_highlight
  end

  def remove
    @selection.remove if @selection
    @border.remove
    @content.remove
    clear_tines
  end

  def stop
    if @pid
      Process.kill "HUP", @pid
      @pid = nil
      @playing = false
      @preview_button.deactivate
    end
  end

  def play
    if @path
      stop if @playing
      @pid = spawn "play -q #{@path} repeat -"
      @playing = true
      @preview_button.activate
    end
  end

  def add
    @track.read unless @track.ready?

    @border = Rectangle.new(
      x: @x - 2,
      y: @y - 2,
      width: @width + 4,
      height: @height + 4,
      color: "black",
      z: @z
    )

    @content = Rectangle.new(
      x: @x,
      y: @y,
      width: @width,
      height: @height,
      color: @color,
      z: @z
    )

    @preview_button = Button.new(
      x: @x,
      y: @y + 60,
      width: 50,
      height: 30,
      label: "preview"
    )

    @preview_button.remove

    @preview_button.on_click do
      @playing ? stop : play
    end

    @buttons = [@preview_button]
  end

  def draw_selection from_nudge = false
    @selection.remove if @selection
    @selection = nil

    return unless @did_move || from_nudge

    head = @rms_tines[@start_index]
    tail = @rms_tines[@end_index]

    tail = head if tail.x <= head.x

    @selection = Rectangle.new(
      x: head.x,
      y: @y,
      width: tail.x + tail.width - head.x,
      height: @height,
      color: "gray",
      z: tail.z - 1
    )
  end

  def nudge start_or_end, direction
    mod = direction == :left ? -1 : 1

    if start_or_end == :start
      new_value = @start_index + mod
      if new_value > 0 && new_value < @end_index
        @start_index = new_value
      end
    else
      new_value = @end_index + mod
      if new_value < @slice_count && new_value > @start_index
        @end_index = new_value
      end
    end

    draw_selection true
    set_track_offsets
  end

  def set_track_offsets
    was_playing = false

    if @playing
      stop
      was_playing = true
    end

    if @selection.nil?
      @track.reset
    else
      start_percent = @start_index.to_f / @slice_count
      end_percent = if @end_index == @slice_count - 1
                      1.0
                    else
                      @end_index.to_f / @slice_count
                    end

      return if start_percent > end_percent

      @track.set_percent_offsets start_percent, end_percent
    end

    write

    play if was_playing

    @path
  end

  def length= new_length_in_measures
    @beat_count = new_length_in_measures * 4 # 4 beats per meaures
  end

  def bpm
    @track.bpm @beat_count
  end

  def write
    @path = @track.write
    @callback.call @path, bpm if @callback
  end

  def set_button_positions
    @preview_button.x = @x + @width - @preview_button.width
    @preview_button.y = @y + 60
  end

  def clear_tines
    @peak_tines.each(&:remove)
    @peak_tines = []
    @rms_tines.each(&:remove)
    @rms_tines = []
  end

  def post_layout
    visualize
  end

  # def zoom dir, x
  #   if dir == :in
  #     index = @rms_tines.index do |t|
  #       t.x <= x && t.x + t.width >= x
  #     end
  #
  #     percent_pos = index.to_f / @slice_count
  #
  #     @track.zoom_in percent_pos
  #   else
  #     @track.zoom_out
  #   end
  # end

  def visualize
    raise unless @track.ready?

    clear_tines

    tine_width = @width / @slice_count.to_f
    rms = RMS.new @slice_count
    buffer = @track.main_buffer
    rms_result = rms.apply buffer, @track.sample_rate, @track.channels
    max_tine_height = @height / 2

    @duration_per_tine = @track.duration / @slice_count
    @max_selectable_tine_count = (30.0 / @duration_per_tine).floor

    i = 0

    while i < @slice_count do
      if @track.channels == 1
        rms_height = rms_result[i][0] * max_tine_height
        above_the_line_height = rms_result[i][1].abs * max_tine_height
        # below_the_line_height = rms_result[i][2].abs * max_tine_height
      else
        rms_height = (
          (rms_result[i][0][1] + rms_result[i][0][1]) / 2
        ) * max_tine_height

        above_the_line_height = (
          (rms_result[i][1][0] + rms_result[i][1][1]) / 2
        ).abs * max_tine_height
        
        # below_the_line_height = (
        #   (rms_result[i][2][0] + rms_result[i][2][1]) / 2
        # ).abs * max_tine_height
      end

      x = @x + i * tine_width

      midpoint = @y + max_tine_height

      @peak_tines << Rectangle.new(
        x: x,
        y: midpoint - above_the_line_height,
        width: tine_width,
        height: above_the_line_height * 2.0,
        color: "black",
        z: @z + 1
      )

      @rms_tines << Rectangle.new(
        x: x,
        y: midpoint - rms_height / 2,
        width: tine_width,
        height: rms_height,
        color: "gray",
        z: @z + 1
      )

      i += 1
    end

    set_track_offsets
    set_button_positions
  end
end

