class Choice
  attr_reader :x, :y, :width, :height

  def initialize attrs = {}
    @label = attrs[:label]
    @value = attrs[:value]
    @x = attrs[:x] || 0
    @y = attrs[:y] || 0
    @width = attrs[:width] || 0
    @height = attrs[:height] || 0
    @choosing = false
    @rendered = false
    @z = attrs[:z] || 0
    add
  end

  def on_choose &block
    @callback = block
  end

  def contains? x, y
    @x <= x && @x + @width >= x && @y < y && @y + @height >= y
  end

  def full_width?
    false
  end

  def x= new_x
    @x = new_x
    @content.x = new_x
    @text.x = new_x + 10
  end

  def y= new_y
    @y = new_y
    @content.y = new_y
    @text.y = new_y + 5
  end

  def width= new_width
  end

  def mouse_down x, y
  end

  def mouse_up x, y
    @content.color = "silver"
    @text.color = "black"
    @callback.call @label, @value if @callback
  end

  def mouse_off
    @content.color = "silver"
    @text.color = "black"
  end

  def mouse_on
    @content.color = "black"
    @text.color = "white"
  end

  def mouse_move x, y
  end

  def remove
    @content.remove
    @text.remove
  end

  def add
    if @rendered
      @content.add
      @text.add
    else
      @content = Rectangle.new(
        x: @x,
        y: @y,
        z: @z,
        color: "silver"
      )

      @text = Text.new(
        @label,
        x: @x,
        y: @y,
        font: File.join(__dir__, "fonts", "lux.ttf"),
        size: 14,
        color: "black",
        z: @z
      )

      @width = @text.width + 20
      @height = @text.height + 10
      @content.width = @width
      @content.height = @height
      @text.x = @x + 10
      @text.y = @y + 5
      @rendered = true
    end
  end
end
