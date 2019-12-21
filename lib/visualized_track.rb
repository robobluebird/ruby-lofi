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
    @slice_count = 500
    @full_width = true
    @highlighting = false
    @selection = nil
    @did_move = false
    @path = nil
    @beat_count = 4
    @pid = nil
    @callback = nil
    @keys = []
    @sx = nil
    @sxe = nil
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

      # shifted = @keys.find { |k| k.include? "shift" }
      # nudge shifted ? :end : :start, key.to_sym
    end
  end

  def content_click x, y
    @content.x <= x && @content.x + @content.width >= x &&
      @content.y <= y && @content.y + @content.height >= y
  end

  def mouse_down x, y
    if content_click x, y
      @highlighting = true

      if @keys.find { |k| k.include? "shift" }
        offset_x = x - @content.x
        @sxe = offset_x if @sx && offset_x > @sx
        draw_selection true
        @did_move = true
      else
        @sx = x - @content.x
        @sxe = @sx
      end
    end
  end

  def mouse_up x, y
    if @highlighting
      @highlighting = false
      draw_selection
      set_track_offsets
      @did_move = false
    end
  end

  def mouse_move x, y
    if @highlighting
      @did_move = true

      offset_x = x - @content.x
      if offset_x > @sx && offset_x < @content.width
        @sxe = offset_x
      end

      draw_selection
    end
  end

  def remove
    @selection.remove if @selection
    @border.remove
    @content.remove
    clear_tines
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
  end

  def draw_selection from_nudge = false
    @selection.remove if @selection
    @selection = nil

    return unless @did_move || from_nudge

    @selection = Rectangle.new(
      x: @sx + @content.x,
      y: @y,
      width: @sxe - @sx,
      height: @height,
      color: "gray",
      z: @content.z
    )
  end

  # def nudge start_or_end, direction
  #   mod = direction == :left ? -1 : 1
  #
  #   if start_or_end == :start
  #     new_value = @start_index + mod
  #     if new_value > 0 && new_value < @end_index
  #       @start_index = new_value
  #     end
  #   else
  #     new_value = @end_index + mod
  #     if new_value < @slice_count && new_value > @start_index
  #       @end_index = new_value
  #     end
  #   end
  #
  #   draw_selection true
  #   set_track_offsets
  # end

  def set_track_offsets
    if @selection.nil?
      @track.reset
    else
      start_percent = @sx.to_f / @content.width
      end_percent = @sxe.to_f / @content.width 

      puts start_percent
      puts end_percent

      return if start_percent > end_percent

      @track.set_percent_offsets start_percent, end_percent
    end

    write

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

  def clear_tines
    @peak_tines.each(&:remove)
    @peak_tines.clear
    @peak_tines = []
    @rms_tines.each(&:remove)
    @rms_tines.clear
    @rms_tines = []
  end

  def post_layout
    # vis3
    # vis2
  end

  def vis3
    # seconds of audio * 4 = 4 tines per second of audio
    tine_count = (@track.buffer.count.to_f / @track.sample_rate) * 4

    w = @width.to_f / tine_count

    # get rms
    group_size = @track.buffer.count / tine_count
    rms = @track.buffer.rms group_size

    # process them
    i = 0
    x = @x
    y = @y + @height / 2

    @tines = []

    puts @width
    puts w
    puts tine_count
    puts group_size

    while i < tine_count
      h = @height * rms[i][0]

      puts rms[i]

      @tines.push Rectangle.new(
        x: x,
        y: y - h,
        width: w,
        height: h * 2,
        color: "black",
        z: 1000
      )

      x += w
      i += 1
    end

    puts "cool"
  end

  def vis2
    MiniMagick::Tool::Convert.new do |convert|
      convert.size "#{@width * 2}x#{@height * 2}"
      convert << 'xc:none'
      convert.fill "rgba(0, 0, 0, 1)"
      tine_width = @width * 2 / @slice_count.to_f
      max_tine_height = @height * 2 / 2
      group_size = @track.buffer.count / @slice_count
      rms = @track.buffer.rms group_size

      i = 0
      bx, by = 0, 0

      while i < @slice_count do
        # rms_height = @rms[i][0] * max_tine_height
        above_the_line_height = rms[i][1].abs * max_tine_height
        midpoint = by + max_tine_height

        x = bx + i * tine_width
        y = midpoint - above_the_line_height
        width = tine_width
        height = above_the_line_height * 2.0

        convert.draw "rectangle #{x},#{y} #{x + width},#{y + height}"

        i += 1
      end

      convert << "project/waveform.png"
    end

    set_track_offsets

    @image = Image.new(
      "project/waveform.png",
      x: @x,
      y: @y,
      width: @width,
      height: @height,
      z: @z + 1
    )
  end
end

