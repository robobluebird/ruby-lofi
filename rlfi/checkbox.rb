class Checkbox
  attr_accessor :x, :y, :size, :tag, :phases

  def initialize x, y, size, checked = false, tag = nil, enabled = true, phases = 1, allow_uncheck = true
    @x = x
    @y = y
    @size = size 
    @checking = false
    @checked = checked
    @tag = tag
    @enabled = enabled
    @hidden = false
    @phases = phases
    @phase = checked ? 1 : 0
    @allow_uncheck = allow_uncheck
  end

  def set_checked c, bubble = true
    @checked = !!c
    @phase = @checked ? 1 : 0
    @callback.call @checked, @tag, @phase, @phases if @callback && bubble
  end

  def allow_uncheck= u
    @allow_uncheck = !!u
  end

  def allow_uncheck?
    @allow_uncheck
  end

  def enabled= e
    @enabled = !!e
  end

  def hidden= h
    @hidden = !!h
  end

  def hidden?
    @hidden
  end

  def enabled?
    @enabled
  end

  def on_change &block
    @callback = block
  end

  def contains? x, y
    @x <= x && @x + @size >= x && @y <= y && @y + @size >= y
  end

  def mouse_down x, y
    return unless enabled?
    
    @checking = true
  end

  def mouse_up x, y, b = :lmb
    return unless enabled?

    if @checking
      if @phase + 1 > @phases
        if @allow_uncheck
          @checked = false
          @phase = 0
        end
      else
        @checked = true
        @phase += 1
      end

      @checking = false
      @callback.call @checked, @tag, @phase, @phases if @callback
    end
  end

  def mouse_update x, y
  end

  def draw
    return if hidden?

    color = @enabled ? Gosu::Color::BLACK : Gosu::Color::GRAY

    Gosu::draw_rect @x, @y, @size, @size, color
    Gosu::draw_rect @x + 1, @y + 1, @size - 2, @size - 2, Gosu::Color::WHITE

    if @checked
      color = Gosu::Color::RED if @phases > 1 && @phase > 1
      Gosu::draw_rect @x + 2, @y + 2, @size - 4, @size - 4, color
    end
  end
end

