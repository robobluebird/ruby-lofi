class Slider
  def initialize x, y, w, min, max, round, snap
    @x = x
    @y = y
    @w = w
    @h = 20

    @sx = x + w.to_f / 2
    @sy = y
    @sw = 20
    @sh = 20

    @min = round ? min.to_i : min
    @max = round ? max.to_i : max
    @value = @min
    @round = round
    @snap = snap
    @enabled = true
  end

  def enabled?
    @enabled
  end

  def enabled= e
    @enabled = !!e
  end

  def slider_position_to_value
    norm_pos = @sx + (@sw / 2) - @x
    val_ratio = norm_pos / @w
    norm_min = 0 - @min
    norm_max = @max - norm_min
    norm_val = norm_max * val_ratio
    norm_val + norm_min
  end

  def value_to_slider_position
    norm_min = 0 - @min
    norm_max = @max - norm_min
    norm_val = @value - norm_min
    val_ratio = norm_val / norm_max
    norm_pos = @w * val_ratio
    @x + norm_pos - (@sw / 2)
  end

  def contains? x, y
  end

  def mouse_down x, y
  end

  def mouse_up x, y
  end

  def update
  end

  def draw
    Gosu::draw_rect @x, @y + @h / 2 - 2.5, @w, 5, Gosu::Color::GRAY
    Gosu::draw_rect value_to_slider_position, @sy, @sw, @sh, Gosu::Color::BLACK
  end
end

