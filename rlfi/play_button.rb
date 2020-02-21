class PlayButton
  attr_accessor :x, :y, :size

  def initialize x, y, size, enabled = true
    @x = x
    @y = y
    @size = size
    @enabled = enabled
    @on = false
  end

  def off
    @on = false
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
    @x <= x && @x + @size >= x && @y <= y && @y + @size >= y
  end

  def mouse_down x, y
    return unless enabled?
    @pressed = true
  end

  def mouse_up x, y
    return unless enabled?
    if @pressed
      @pressed = false
      @on = !@on
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
    Gosu::draw_rect @x, @y, @size, @size, bgc

    if @on
      Gosu::draw_rect @x + 2, @y, 2, @size, tc
      Gosu::draw_rect @x + 6, @y, 2, @size, tc
    else
      Gosu::draw_triangle @x, @y, tc, @x + @size, @y + @size / 2.0, tc, @x, @y + @size, tc
    end
  end
end
