class PatternStep
  attr_reader :x, :y, :radius, :step_number, :checked

  def initialize opts = {}
    @x = opts[:x] || 0
    @y = opts[:y] || 0
    @z = opts[:z] || 0
    @radius = opts[:radius] || 0
    @color = opts[:color] || "black"
    @outer = nil
    @inner = nil
    @check = nil
    @checking = false
    @checked = opts[:checked] || false
    @callback = nil
    @step_number = opts[:step_number] || -1
    add
  end

  def contains? x, y
    @outer.contains? x, y
  end

  def x= new_x
    @x = new_x
    @outer.x = new_x
    @inner.x = new_x + 0.34
    @check.x = new_x + 0.45
  end

  def y= new_y
    @y = new_y
    @outer.y = new_y
    @inner.y = new_y + 0.34
    @check.y = new_y + 0.45
  end

  def on_change &block
    @callback = block
  end

  def mouse_down x, y
    @checking = true
  end

  def mouse_up x, y
    if @checking
      @checking = false
      @checked = !@checked
      @check.color = checked? ? "black" : "white"
      @callback.call @step_number, @checked if @callback
    end
  end

  def width= new_width
  end

  def checked?
    @checked
  end

  def remove
    @outer.remove
    @inner.remove
    @check.remove
  end

  def add
    @outer = Circle.new(
      x: @x,
      y: @y,
      z: @z,
      radius: @radius,
      color: @color
    )

    @inner = Circle.new(
      x: @x + 0.34,
      y: @y + 0.34,
      z: @z,
      radius: @radius - 1,
      color: "white"
    )

    @check = Circle.new(
      x: @x + 45,
      y: @y + 45,
      z: @z,
      radius: @radius - 2,
      color: "white"
    )
  end
end
