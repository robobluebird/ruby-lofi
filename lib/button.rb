require "ruby2d"

class Button
  attr_reader :x, :y, :width, :height, :label
  attr_accessor :enabled

  def initialize attrs = {}
    @label = attrs[:label] || "button"
    @x = attrs[:x] || 0
    @y = attrs[:y] || 0
    @width = attrs[:width] || 200
    @height = attrs[:height] || 100
    @color = attrs[:color] || "white"
    @z = attrs[:z] || 0
    @opacity = attrs[:opacity] if attrs[:opacity]
    @border = nil
    @content = nil
    @text = nil
    @enabled = attrs[:enabled].nil? ? true : attrs[:enabled]
    @full_width = false
    add
  end

  def enabled= status
    @enabled = status

    if status
      @text.color = "black"
      @border.color = "black"
    else
      @text.color = "gray"
      @border.color = "gray"
    end
  end

  def opacity= new_op
    @border.opacity = new_op
    @content.opacity = new_op
    @text.opacity = new_op
  end

  def activate
    @content.color = "green"
  end

  def deactivate
    @content.color = "white"
  end

  def contains? x, y
    @content.x <= x && @content.x + @content.width >= x &&
      @content.y <= y && @content.y + @content.height >= y
  end

  def on_click &block
    @callback = block
  end

  def full_width?
    @full_width
  end

  def x= new_x
    @x = new_x
    @content.x = new_x
    @border.x = new_x - 2
    @text.x = new_x + (@width / 2) - (@text.width / 2)
  end

  def y= new_y
    @y = new_y
    @content.y = new_y
    @border.y = new_y - 2
    @text.y = new_y + (@height / 2) - (@text.height / 2)
  end

  def width= new_width
    @width = new_width
    @content.width = new_width
    @border.width = new_width + 4
    @text.x = @x + (new_width / 2) - (@text.width / 2)
  end

  def mouse_down x, y
    return unless @enabled
    @border.color = "white"
    @content.color = "black"
    @text.color = "white"
  end

  def mouse_up x, y
    return unless @enabled
    @border.color = "black"
    @content.color = "white"
    @text.color = "black"
    @callback.call if @callback
  end

  def mouse_move x, y
    return unless @enabled
  end

  def remove
    @border.remove
    @content.remove
    @text.remove
  end

  def add
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

    @text = Text.new(
      @label,
      font: File.join(__dir__, "fonts", "lux.ttf"),
      size: 14,
      color: "black",
      z: @z
    )

    @text.x = @x + (@width / 2) - (@text.width / 2)
    @text.y = @y + (@height / 2) - (@text.height / 2)

    if @text.width > @width - 20
      self.width = @text.width + 20
    end

    self.enabled = @enabled
  end
end
