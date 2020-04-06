class Selection
  attr_reader :w, :h, :x, :y, :buffer, :path, :primary_color, :secondary_color
  attr_accessor :deleteable

  def initialize buffer, path, sample_rate, channels, speed = 1.0, delay = 0.0, decay = 0.0, level = 0, volume = 1.0
    @buffer = buffer
    @path = path
    @sample_rate = sample_rate
    @channels = channels
    @speed = speed
    @delay = delay
    @decay = decay
    @level = level
    @volume = volume
    @moused = false
    @deleteable = true
    @w = 100
    @h = 50
    @x = 0
    @y = 0

    @delete_button = Button.new "x", 0, 0
    @delete_button.on_click do
      @delete_callback.call if @delete_callback
    end
  end

  def contains? x, y
    x >= @x && x <= @x + @w && y >= y && y <= @y + @h
  end

  def color= color
    @primary_color   = Gosu::Color.argb color.alpha, color.red, color.blue, color.green
    @secondary_color = Gosu::Color.argb color.alpha.to_f / 2, color.red, color.blue, color.green
  end

  def on_delete &block
    @delete_callback = block
  end

  def x= new_x
    @x = new_x
    @delete_button.x = @x + @w - @delete_button.width
  end

  def y= new_y
    @y = new_y
    @delete_button.y = @y
  end

  def mouse_down x, y
    @delete_button.mouse_down x, y if @delete_button.contains?(x, y) && @deleteable
    @moused = true
  end

  def mouse_up x, y
    if @moused
      @delete_button.mouse_up x, y if @delete_button.contains?(x, y) && @deleteable
      @moused = false
    end
  end

  def mouse_update x, y
  end

  def rms
    @rms ||= begin
      return [] unless @buffer
      rms = RMS.new @w
      rms.apply @buffer, @sample_rate, @channels
    end
  end

  def draw
		h = @h / 2
    @delete_button.draw if @deleteable
    rms.each.with_index do |r, i|
      max = r[1] * h
      min = r[2].abs * h
      rms = r[0] * h
      Gosu::draw_rect @x + i, @y + h - max, 1, max, @secondary_color
      Gosu::draw_rect @x + i, @y + h, 1, min, @secondary_color
      Gosu::draw_rect @x + i, @y + h - rms, 1, rms * 2, @primary_color
    end
  end
end
