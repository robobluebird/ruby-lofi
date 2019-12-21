class Checkbox
  attr_accessor :x, :y, :size, :checked

  def initialize x, y, size, checked
    @x = x
    @y = y
    @size = size 
    @checked = false
    @enabled = true
  end

  def enabled= e
    @enabled = !!e
  end

  def enabled?
    @enabled
  end

  def contains? x, y
    @x <= x && @x + @size >= x && @y <= y && @y + @size >= y
  end

  def mouse_down x, y
    return unless enabled?
  end

  def mouse_up x, y
    return unless enabled?

    @checked = !@checked
  end

  def draw
    color = @enabled ? Gosu::Color::BLACK : Gosu::Color::GRAY

    Gosu::draw_rect @x, @y, @size, @size, color
    Gosu::draw_rect @x + 1, @y + 1, @size - 2, @size - 2, Gosu::Color::WHITE

    if @checked
      Gosu::draw_rect @x + 2, @y + 2, @size - 4, @size - 4, color
    end
  end
end

