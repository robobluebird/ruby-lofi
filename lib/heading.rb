class Heading
  attr_reader :x, :y, :width, :height, :label

  def initialize opts = {}
    @label = opts[:label] || ""
    @x = opts[:x] || 0
    @y = opts[:y] || 0
    @width = opts[:width] || 0
    @height = opts[:height] || 0
    @content = nil
    @text = nil
    add
  end

  def contains? x, y
    @content.x <= x && @content.x + @content.width >= x &&
      @content.y <= y && @content.y + @content.height >= y
  end

  def mouse_down x, y
  end

  def mouse_up x, y
  end

  def mouse_move x, y
  end

  def x= new_x
    @x = new_x
    @content.x = new_x
    @text.x = @content.x + @content.width / 2 - @text.width / 2

    line_y = @y + @height / 2

    @left_line.x1 = @x
    @left_line.y1 = line_y
    @left_line.x2 = @text.x - 10
    @left_line.y2 = line_y

    @right_line.x1 = @text.x + @text.width + 10
    @right_line.y1 = line_y
    @right_line.x2 = @width
    @right_line.y2 = line_y
  end

  def y= new_y
    @y = new_y
    @content.y = new_y
    @text.y = new_y

    line_y = @y + @height / 2

    @left_line.x1 = @x
    @left_line.y1 = line_y
    @left_line.x2 = @text.x - 10
    @left_line.y2 = line_y

    @right_line.x1 = @text.x + @text.width + 10
    @right_line.y1 = line_y
    @right_line.x2 = @width
    @right_line.y2 = line_y
  end

  def width= new_width
    @width = new_width
    @content.width = new_width
    @text.x = @content.x + @content.width / 2 - @text.width / 2

    line_y = @y + @height / 2

    @left_line.x1 = @x
    @left_line.y1 = line_y
    @left_line.x2 = @text.x - 10
    @left_line.y2 = line_y

    @right_line.x1 = @text.x + @text.width + 10
    @right_line.y1 = line_y
    @right_line.x2 = @width
    @right_line.y2 = line_y
  end

  def full_width?
    true
  end

  def remove
    @content.remove
    @text.remove
    @left_line.remove
    @right_line.remove
  end

  def add
    @content = Rectangle.new(
      x: @x,
      y: @y,
      width: @width,
      height: @height
    )

    @text = Text.new(
      @label,
      x: 0,
      y: 0,
      size: 14,
      font: File.join(__dir__, "fonts", "lux.ttf"),
      color: "black"
    )
    
    @left_line = Line.new(
      x1: @x,
      y1: @y,
      x2: @text.x,
      y2: @y,
      width: 1,
      color: "black"
    )

    @right_line = Line.new(
      x1: @text.x + @text.width,
      y1: @y,
      x2: @width,
      y2: @y,
      width: 1,
      color: "black"
    )

    @height = @text.height
    @content.height = @text.height
    @text.x = @x + @width / 2 - @text.width / 2
  end
end
