class PlayButton
  def on_change &block
  end

  def contains? x, y
    @x <= x && @x + @size >= x && @y <= y && @y + @size >= y
  end

  def mouse_down x, y
  end

  def mouse_up x, y, b = :lmb
  end

  def mouse_update x, y
  end

  def draw
end
