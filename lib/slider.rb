class Slider
  attr_reader :x, :y, :width, :height, :min, :max, :value, :tag

  def initialize attrs = {}
    @tag = attrs[:tag]
    @label = attrs[:label] || "button"
    @x = attrs[:x] || 0
    @y = attrs[:y] || 0
    @width = attrs[:width] || 200
    @height = attrs[:height] || 25
    @color = attrs[:color] || "white"
    @z = attrs[:z] || 0
    @opacity = attrs[:opacity] if attrs[:opacity]
    @min = attrs[:min] || 0
    @max = attrs[:max] || 1
    @value = attrs[:value] || 0.5
    @default_value = attrs[:default_value] || @value
    @content = nil
    @border = nil
    @handle = nil
    @track = nil
    @track_offset = 100
    @text = nil
    @full_width = false
    @callback = nil
    @lower_track_bound = nil
    @upper_track_bound = nil
    @handle_offset = 10.0
    @rendered = false
    @enabled = attrs[:enabled].nil? ? true : attrs[:enabled]
    @min_label = nil
    @mid_label = nil
    @max_label = nil
    @value_label = nil
    @show_value = attrs[:show_value].nil? ? false : attrs[:show_value]
    @round_value = attrs[:round_value].nil? ? false : attrs[:round_value]
    add
  end

  def full_width?
    @full_width
  end

  def enabled?
    @enabled
  end

  def enabled= status
    if status
      border_opacity = @border.opacity
      @border.color = "black"
      @border.opacity = border_opacity
      @text.color = "black"
      @handle.color = "black"
    else
      border_opacity = @border.opacity
      @border.color = "gray"
      @border.opacity = border_opacity
      @text.color = "gray"
      @handle.color = "gray"
    end

    @enabled = status
  end

  def on_change &block
    @callback = block
  end

  def contains? x, y
    @content.x <= x && @content.x + @content.width >= x &&
      @content.y <= y && @content.y + @content.height >= y
  end

  def x= new_x
    @x = new_x
    @content.x = new_x
    @border.x = new_x - 2
    @text.x = new_x
    @track.x = new_x + @track_offset
    @handle.x = value_to_slider_position
    @min_label.x = @track.x - (@min_label.width.to_f / 2)
    @mid_label.x = @track.x + (@track.width.to_f / 2) - (@mid_label.width.to_f / 2)
    @max_label.x = @track.x + @track.width - (@max_label.width.to_f / 2)
    @value_label.x = @track.x + @track.width + 10

    squish
  end

  def y= new_y
    @y = new_y
    @content.y = new_y
    @border.y = new_y - 2
    @text.y = new_y + (@height / 2) - (@text.height / 2)
    @track.y = new_y + @height / 2 - 5
    @handle.y = new_y + @height / 2 - 10
    @min_label.y = @track.y - @min_label.height * 1.5
    @mid_label.y = @track.y - @mid_label.height * 1.5
    @max_label.y = @track.y - @max_label.height * 1.5
    @value_label.y = @track.y
    squish
  end

  def width= new_width
    @width = new_width
    @content.width = new_width
    @border.width = new_width + 4
    @text.x = @x + 10
    @track_offset =  @text.x + @text.width
    @track.x = @x + @track_offset
    @handle.x = value_to_slider_position
    @min_label.x = @track.x - (@min_label.width.to_f / 2)
    @mid_label.x = @track.x + (@track.width.to_f / 2) - (@mid_label.width.to_f / 2)
    @max_label.x = @track.x + @track.width - (@max_label.width.to_f / 2)
    @value_label.x = @track.x + @track.width + 10
  end

  def squish
    @width = @text.width + 20 + 100 + 20
    @track_offset = @text.width + 20
    @content.width = @width
    @border.width = @width + 4
    @text.x = @x
    @track.x = @x + @track_offset
    @handle.x = value_to_slider_position
    @lower_track_bound = @track.x - @handle_offset
    @upper_track_bound = @track.x + @track.width - @handle_offset
    @min_label.x = @track.x - (@min_label.width.to_f / 2)
    @mid_label.x = @track.x + (@track.width.to_f / 2) - (@mid_label.width.to_f / 2)
    @max_label.x = @track.x + @track.width - (@max_label.width.to_f / 2)
    @value_label.x = @track.x + @track.width + 10
  end

  def reset
    self.value = @default_value
  end

  def value= value
    value = rounded_value(value) if @round_value
    @value = value
    @handle.x = value_to_slider_position
    @value_label.text = value.floor
  end

  def max_offset_percent_value
    (@max - @value) / (@max - @min)
  end

  def mouse_down x, y
    return unless @enabled

    @dragging = @handle.x <= x && @handle.x + @handle.width >= x &&
      @handle.y <= y && @handle.y + @handle.height >= y
  end

  def mouse_up x, y
    return unless @enabled

    if @dragging
      @value = slider_position_to_value
      @dragging = false
      @callback.call value if @callback
    end
  end

  def mouse_move x, y
    return unless @enabled

    if @dragging
      @handle.x = x - @handle.width.to_f / 2

      if @handle.x < @lower_track_bound
        @handle.x = @lower_track_bound
      elsif @handle.x > @upper_track_bound
        @handle.x = @upper_track_bound
      end

      @value_label.text = slider_position_to_value.round(2)
    end
  end

  def rounded_value value
    value = value.ceil
    value = value - 1 if value > @max
    value
  end

  def slider_position_to_value
    range = @max - @min
    normalized_slider_position = @handle.x + @handle_offset - @track.x
    percentage_of_whole = normalized_slider_position / @track.width
    spot_on_range = percentage_of_whole * range
    offset_from_max = range - spot_on_range
    value = @max - offset_from_max
    @round_value ? rounded_value(value) : value
  end

  def value_to_slider_position
    range = @max - @min
    offset_from_max = @max - @value
    spot_on_range = range - offset_from_max
    percentage_of_whole = spot_on_range.to_f / range
    normalized_slider_position = @track.width * percentage_of_whole
    normalized_slider_position - @handle_offset + @track.x
  end

  def remove
    @border.remove
    @content.remove
    @text.remove
    @track.remove
    @handle.remove
    @min_label.remove
    @mid_label.remove
    @max_label.remove
    @value_label.remove
    self
  end

  def add
    if @rendered
      @border.add
      @content.add
      @text.add
      @track.add
      @handle.add
      @min_label.add
      @mid_label.add
      @max_label.add
      @value_lable.add
    end
      
    @border = Rectangle.new(
      x: @x - 2,
      y: @y - 2,
      width: @width + 4,
      height: @height + 4,
      color: "black",
      z: @z,
      opacity: 0
    )

    @content = Rectangle.new(
      x: @x,
      y: @y,
      width: @width,
      height: @height,
      color: @color,
      z: @z
    )

    @text = Text.new(
      @label,
      x: @x,
      y: @y,
      font: File.join(__dir__, "fonts", "lux.ttf"),
      size: 14,
      color: "black"
    )

    @text.y = @y + (@height / 2) - (@text.height / 2)
  
    @track = Rectangle.new(
      x: @x + @track_offset,
      y: @y + @height / 2 - 5,
      width: 100,
      height: 10,
      color: "gray"
    )

    @handle = Rectangle.new(
      x: 0,
      y: @y + @height / 2 - 10,
      width: 20,
      height: 20,
      color: "black"
    )

    @min_label = Text.new(
      @min.to_s,
      x: @track.x,
      y: @track.y,
      font: File.join(__dir__, "fonts", "lux.ttf"),
      size: 10,
      color: "black"
    )

    @mid_label = Text.new(
      ((@max + @min).to_f / 2).to_s,
      x: @track.x + @track.width.to_f / 2,
      y: @track.y,
      fant: File.join(__dir__, "fonts", "lux.ttf"),
      size: 10,
      color: "black",
      opacity: 0
    )

    @value_label = Text.new(
      @round_value ? rounded_value(@value) : @value,
      x: @track.x + @track.width + 10,
      y: @track.y,
      fant: File.join(__dir__, "fonts", "lux.ttf"),
      size: 10,
      color: "black",
      opacity: @show_value ? 1 : 0
    )

    @max_label = Text.new(
      @max.to_s,
      x: @track.x + @track.width,
      y: @track.y,
      font: File.join(__dir__, "fonts", "lux.ttf"),
      size: 10,
      color: "black"
    )

    @handle.x = value_to_slider_position
    self.squish
    self.enabled = @enabled
    @rendered = true

    self
  end
end
