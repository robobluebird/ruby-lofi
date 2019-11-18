class VerticalLayout
  attr_reader :x, :y, :width, :height, :elements

  def initialize attrs = {}
    @label = attrs[:label]
    @heading = nil
    @show_heading = attrs[:show_heading]
    @border = nil
    @content = nil
    @show_border = attrs[:show_border]
    @x = 0
    @y = 0
    @horizontal_margin = attrs[:horizontal_margin] || 20
    @vertical_margin = attrs[:vertical_margin] || 20
    @width = attrs[:width]
    @height = 0
    @elements = []

    if @show_border
      @border = Rectangle.new(
        x: @x - 2,
        y: @y - 2,
        width: @width + 4,
        height: @height + 4,
        color: "black"
      )

      @content = Rectangle.new(
        x: @x,
        y: @y,
        width: @width,
        height: @height,
        color: "white"
      )
    end

    if @label && @show_heading
      @heading = Text.new(
        @label,
        y: 0,
        x: 0,
        font: File.join(__dir__, "fonts", "lux.ttf"),
        size: 14,
        color: "black",
      )

      @heading.x = @x + @width / 2 - @heading.width / 2
    end
  end

  def adjust_border
    return unless @show_border
    @border.x = @x - 2
    @border.y = @y - 2
    @border.width = @width + 4
    @border.height = @height + 4
    @content.x = @x
    @content.y = @y
    @content.width = @width
    @content.height = @height
  end

  def x= new_x
    @x = new_x
    @heading.x = @x + @width / 2 - @heading.width / 2 if @heading
    adjust_border
    @elements.each { |e| e.x = new_x }
  end

  def y= new_y
    diff = new_y - @y
    @y = new_y

    if @heading
      @heading.y = @y
      diff += @heading.height
    end

    adjust_border
    @elements.each do |e|
      e.y = e.y + diff
    end
  end

  def width= new_width
    @width = new_width
    @heading.x = @x + @width / 2 - @heading.width / 2 if @heading
    adjust_border
    @elements.each do |e|
      e.width = new_width if e.full_width?
    end
  end

  def element_at x, y
    @elements.find do |element|
      element.x <= x && element.x + element.width >= x &&
        element.y <= y && element.y + element.height >= y
    end
  end

  def delete_at index
    return if index < 0 || index > @elements.count - 1

    height = @elements[index].height
    @elements[index].remove
    element = @elements.delete_at index
    bump_elements_to_index index, height + @vertical_margin
    set_height
    element
  end

  def insert index, element, justify = :left
    case justify
    when :left
      if index >= @elements.count
        append element, justify
      else
        element.x = @horizontal_margin
        element.y = @elements[index].y
        element.width = @width - @horizontal_margin * 2 if element.full_width?
        element.post_layout if element.respond_to? :post_layout
        bump_elements_from_index index, element.height + @vertical_margin
        @elements.insert index, element
        set_height
      end
    when :right
      raise "nop"
    when :center
      raise "nop"
    else
      raise "nop"
    end

    self
  end

  def bump_elements_to_index index, amount
    @elements[index..-1].each do |el_to_bump|
      el_to_bump.y -= amount
      el_to_bump.post_layout if el_to_bump.respond_to? :post_layout
    end
  end

  def bump_elements_from_index index, amount
    @elements[index..-1].each do |el_to_bump|
      el_to_bump.y += amount
      el_to_bump.post_layout if el_to_bump.respond_to? :post_layout
    end
  end

  def set_height
    @height = calculated_height +
      (@heading ? @heading.height : 0)
    adjust_border
  end

  def append element,  justify = :left
    case justify
    when :left
      element.x = @horizontal_margin
      element.y = next_height
      element.width = @width - @horizontal_margin * 2 if element.full_width?
      element.post_layout if element.respond_to? :post_layout
      (element.y + element.height).tap { |h| @height = h if h > @height }
      @elements << element
      set_height
    when :right
      raise "nop"
    when :center
      raise "nop"
    else
      raise "nop"
    end

    self
  end

  def calculated_height
    y = @heading ? @heading.height : 0
    @elements.reduce(y) do |acc, obj|
      acc += @vertical_margin + obj.height
    end
  end

  def next_height
    calculated_height + @vertical_margin
  end

  def remove
    @elements.each(&:remove)
    @elements.clear
  end

  def render
    remove 
    @elements.each(&:add)
  end
end
