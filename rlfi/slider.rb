class Slider
  attr_reader :x, :y, :w, :h, :value

  def initialize x, y, w, min, max, initial_value = nil, round = false
    @x = x
    @y = y
    @w = w
    @h = 20

    @min = round ? min.to_i : min
    @max = round ? max.to_i : max
    val = initial_value ? initial_value : min
    val.to_i if round
    @value = val
    @round = round
    @enabled = true

    @sw = 20
    @sh = 20
    @sx = value_to_slider_position
    @sy = y
    @sliding = false

    @callback = nil
  end

  def enabled?
    @enabled
  end

  def enabled= e
    @enabled = !!e
  end

  def on_change &block
    @callback = block
  end

  def slider_position_to_value
    norm_pos = @sx + (@sw.to_f / 2) - @x
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
    val_ratio = norm_val.to_f / norm_max
    norm_pos = @w * val_ratio
    puts val_ratio, norm_pos
    @x + norm_pos - (@sw / 2)
  end

  def contains? x, y
    @x <= x && @x + @w >= x && @y <= y && @y + @h >= y
  end

  def mouse_down x, y
    if @sx <= x && @sx + @sw >= x && @sy <= y && @sy + @sh >= y
      @sliding = true
    end
  end

  def mouse_up x, y
    @sliding = false
    @value = slider_position_to_value
    @callback.call @value if @callback
  end

  def mouse_update x, y
    if @sliding
      if x < @x - 10
        @sx = @x - 10
      elsif x > @x + @w - 10
        @sx = @x + @w - 10
      else
        @sx = x - 10
      end
    end
  end

  def draw
    Gosu::draw_rect @x, @y + @h / 2 - 2.5, @w, 5, Gosu::Color::GRAY
    Gosu::draw_rect @sx, @sy, @sw, @sh, Gosu::Color::BLACK
  end
end

