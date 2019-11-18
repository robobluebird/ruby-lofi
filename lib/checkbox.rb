class Checkbox
  attr_reader :x, :y, :width, :height, :checked

  def initialize attrs = {}
    @label = attrs[:label] || ""
    @x = attrs[:x] || 0
    @y = attrs[:y] || 0
    @width = attrs[:width] || 200
    @check_size = attrs[:check_size] || 20
    @height = attrs[:height] || 100
    @color = attrs[:color] || "white"
    @z = attrs[:z] || 0
    @opacity = attrs[:opacity] || 1.0
    @enabled = attrs[:enabled] || true
    @checked = attrs[:checked] || false
    @border = nil
    @content = nil
    @check = nil
    @text = nil
    @checking = false
    @rendered = false
    @callback = nil
    add
  end

  def contains? x, y
    @content.x <= x && @content.x + @content.width >= x &&
      @content.y <= y && @content.y + @content.height >= y
  end

  def on_change &block
    @callback = block
  end

  def checked?
    @checked
  end

  def full_width?
    false
  end

  def x= new_x
    @x = new_x
    @content.x = new_x
    @text.x = new_x
    @border.x = new_x + @text.width + 20 - 2
    @inner_block.x = new_x + @text.width + 20  + 1
    @check.x = new_x + @text.width + 20 + 1
  end

  def y= new_y
    @y = new_y
    @border.y = new_y - 2
    @content.y = new_y
    @check.y = new_y + 1
    @inner_block.y = new_y + 1
    @text.y = new_y + (@height / 2) - (@text.height / 2)
  end

  def width= new_width
  end

  def mouse_down x, y
    @checking = true
  end

  def mouse_up x, y
    if @checking
      @checking = false
      @checked = !@checked
      @check.color = checked? ? "black" : "white"
      @callback.call @checked if @callback
    end
  end

  def mouse_move x, y
  end

  def remove
    @border.remove
    @content.remove
    @inner_block.remove
    @check.remove
    @text.remove
    self
  end

  def add
    if @rendered
      @content.add
      @border.add
      @inner_block.add
      @check.add
      @text.add
      return
    end

    @content = Rectangle.new(
      width: 0,
      height: @check_size,
      z: @z
    )

    @border = Rectangle.new(
      width: @check_size + 4,
      height: @check_size + 4,
      color: "black",
      z: @z
    )
    
    @inner_block = Rectangle.new(
      width: @check_size - 2,
      height: @check_size - 2,
      color: "white",
      z: @z
    )

    @check = Rectangle.new(
      width: @check_size - 2,
      height: @check_size - 2,
      color: checked? ? "black" : "white",
      z: @z
    )

    @text = Text.new(
      @label,
      font: File.join(__dir__, "fonts", "lux.ttf"),
      size: 14,
      color: "black"
    )

    @text.y = @y + (@height / 2) - (@text.height / 2)
    self.x = @x
    @width = @text.width + 20 + @border.width
    @content.width = @width
    @height = @border.height
    @rendered = true

    self
  end
end
