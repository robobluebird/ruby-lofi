class HorizontalLayout
  attr_reader :x, :y, :width, :height, :elements

  def initialize max_width = nil
    @vertical_margin = 20
    @horizontal_margin = 20
    @x = 0
    @y = 0
    @height = 0
    @width = 0
    @max_width = max_width
    @elements = []
  end

  def mouse_down x, y
    element = element_at x, y
    if element && element.respond_to?(:mouse_down)
      element.mouse_down x, y
      @chooser = element if element.is_a? Chooser
    end
  end

  def mouse_up x, y
    if @chooser
      @chooser.mouse_up x, y
      @chooser = nil
    else
      element = element_at x, y
      element.mouse_up x, y if element && element.respond_to?(:mouse_up)
    end
  end

  def mouse_move x, y
    if @chooser
      @chooser.mouse_move x, y
    else
      element = element_at x, y
      element.mouse_move x, y if element && element.respond_to?(:mouse_move)
    end
  end

  def full_width?
    true
  end

  def width= new_width
    @max_width = new_width
  end

  def x= new_x
    diff = new_x - @x
    @x = new_x
    @elements.each do |element|
      element.x = element.x + diff
    end
  end

  def y= new_y
    @y = new_y
    @elements.each { |e| e.y = new_y }
  end

  def set_width
    width = 0
    i = 0
    while i < @elements.count do
      width += @elements[i].width
      width += @horizontal_margin unless i == @elements.count - 1
      i += 1
    end
    @width = width
  end

  def set_height
    @elements.each do |element|
      @height = element.height if element.height > @height
    end
  end

  def next_x
    @elements.reduce(0) do |acc, obj|
      acc += obj.width + @horizontal_margin
    end
  end

  def append element
    element.x = next_x + @x
    @elements << element
    set_width
    set_height
    element.y = @y + @height / 2 - element.height / 2
    element.post_layout if element.respond_to? :post_layout
    self
  end

  def element_at x, y
    @elements.find do |element|
      element.x <= x && element.x + element.width >= x &&
        element.y <= y && element.y + element.height >= y
    end
  end

  def remove
    @elements.each(&:remove)
  end

  def render
    remove
    @elements.each(&:add)
  end
end
