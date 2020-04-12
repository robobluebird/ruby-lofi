class Slider
  attr_reader :x, :y, :w, :h, :value
  attr_accessor :show_value

  def initialize x, y, w, min, max, initial_value = nil, round = false, show_value = false
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

    @tx = @x + 10
    @tw = @w - 20

    @sw = 20
    @sh = 20
    @sx = value_to_slider_position
    @sy = y
    @sliding = false

    @value_text = Gosu::Image.from_text @value.round(2).to_s, 12
    @show_value = show_value

    @callback = nil
  end

  def round?
    @round
  end

  def y= new_y
    @y = new_y
    @sy = @y
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
    norm_pos = @sx + (@sw / 2.0) - @tx
    val_ratio = norm_pos / @tw
    range = @max - @min
    val = val_ratio * range + @min
    round? ? val.to_i : val
  end

  def value_to_slider_position
    norm_shift = 0 - @min
    norm_max = @max + norm_shift
    norm_val = @value + norm_shift
    val_ratio = norm_val.to_f / norm_max
    norm_pos = @tw * val_ratio
    @tx + norm_pos - (@sw / 2)
  end

  def contains? x, y
    @x <= x && @x + @w >= x && @y <= y && @y + @h >= y
  end

  def mouse_down x, y
    if @sx <= x && @sx + @sw >= x && @sy <= y && @sy + @sh >= y
      @sliding = true
      @relative_mouse_x = x - @sx
    end
  end

  def mouse_up x, y
    @sliding = false
    @value = slider_position_to_value
    @relative_mouse_x = nil
    @value_text = Gosu::Image.from_text @value.round(2).to_s, 12
    @callback.call @value if @callback
  end

  def mouse_update x, y
    if @sliding
      hw = @sw / 2.0
      nx = x - @relative_mouse_x
      if nx < @tx - hw
        @sx = @tx - hw
      elsif nx > @tx + @tw - hw
        @sx = @tx + @tw - hw
      else
        @sx = nx
      end
      @value = slider_position_to_value
      @value_text = Gosu::Image.from_text @value.round(2).to_s, 12
    end
  end

  def draw
    Gosu::draw_rect @tx, @y + @h / 2 - 2.5, @tw, 5, Gosu::Color::GRAY
    Gosu::draw_rect @sx + @sw / 4.0, @sy, @sw / 2.0, @sh, Gosu::Color::BLACK
    @value_text.draw @tx + @tw + 10, @y + @h / 2 - 5, 1, 1, 1, Gosu::Color::BLACK if @show_value
  end
end

