class Button
  attr_reader :width, :height, :label, :x, :y

  def initialize label, x, y, enabled = true
    @label = x
    @text = Gosu::Image.from_text label, 20
    @x = x
    @y = y
    @height = @text.height
    @width = @text.width
    @enabled = enabled
  end

  def x= new_x
    @x = new_x
  end

  def y= new_y
    @y = new_y
  end

  def label= new_label
    @label = label
    @text = Gosu::Image.from_text label, 16
    @height = @text.height
    @width = @text.width
  end

  def on_click &block
    @callback = block
  end

  def enabled= e
    @enabled = !!e
  end

  def enabled?
    @enabled
  end

  def white
    Gosu::Color::WHITE
  end

  def black
    Gosu::Color::BLACK
  end

  def gray
    Gosu::Color::GRAY
  end

  def contains? x, y
    @x <= x && @x + @width >= x && @y <= y && @y + @height >= y
  end

  def mouse_down x, y
    return unless enabled?

    @pressed = true
  end

  def mouse_up x, y
    return unless enabled?

    if @pressed
      @pressed = false
      @callback.call if @callback
    end
  end

  def pressed?
    @pressed
  end

  def mouse_update x, y
    return unless enabled?
  end

  def draw
    tc, bgc = enabled? ? pressed? ? [white, black] : [black, white] : [gray, white]
    Gosu::draw_rect @x, @y, @width, @height, bgc
    @text.draw @x, @y - 5, 1, 1, 1, tc
  end
end
