class Chooser
  attr_reader :x, :y, :width, :height, :label, :value, :tag

  def initialize attrs = {}
    @tag = attrs[:tag]
    @label = attrs[:label] || "none"
    @value = attrs[:value] || "none"
    @choices = attrs[:choices] || []
    @x = attrs[:x] || 0
    @y = attrs[:y] || 0
    @z = attrs[:z] || 0
    @width = attrs[:width] || 0
    @height = attrs[:height] || 0
    @choosing = false
    @choice_elements = []
    add
  end

  def on_change &block
    @callback = block
  end

  def contains? x, y
    @x <= x && @x + @width >= x && @y < y && @y + @height >= y
  end

  def full_width?
    false
  end

  def x= new_x
    @x = new_x
    @content.x = new_x
    @text.x = new_x
  end

  def y= new_y
    @y = new_y
    @content.y = new_y
    @text.y = new_y
  end

  def width= new_width
  end

  def mouse_down x, y
    @choosing = true
    @content.color = "black"
    @text.color = "white"
    show_choices 
  end

  def mouse_up x, y
    if @choosing
      @choosing = false
      @content.color = "white"
      @text.color = "black"

      choice = @choice_elements.find do |element|
        element.x <= x && element.x + element.width >= x &&
          element.y <= y && element.y + element.height >= y
      end

      choice.mouse_up x, y if choice

      hide_choices
    end
  end

  def mouse_move x, y
    @choice_elements.each(&:mouse_off)

    choice = @choice_elements.find do |element|
      element.x <= x && element.x + element.width >= x &&
        element.y <= y && element.y + element.height >= y
    end

    choice.mouse_on if choice
  end

  def remove
    @content.remove
    @text.remove
  end

  def add
    @content = Rectangle.new(
      x: @x,
      y: @y,
      width: @width,
      height: @height,
      z: @z
    )

    @text = Text.new(
      @label,
      x: @x,
      y: @y,
      font: File.join(__dir__, "fonts", "lux.ttf"),
      size: 14,
      color: "black",
      z: @z
    )

    set_dimensions
  end

  def set_dimensions
    @width = @text.width
    @height = @text.height
    @content.width = @width
    @content.height = @height
  end

  def show_choices
    x = @x + @width
    y = 0

    if @choice_elements.any?
      total_height = @choice_elements.reduce(0) { |acc, elem| acc += elem.height }
      y = [@y - total_height / 2, 0].max

      @choice_elements.each do |elem|
        elem.x = x
        elem.y = y
        elem.add
        y += elem.height
      end
    else
      @choice_elements = @choices.map do |choice|
        choice_element = Choice.new(
          label: choice[:label],
          value: choice[:value],
          x: x,
          y: y,
          z: @z
        )
        y += choice_element.height
        choice_element
      end

      total_height = @choice_elements.reduce(0) { |acc, elem| acc += elem.height }
      y = [@y - total_height / 2, 0].max

      @choice_elements.each do |choice|
        choice.y = y
        y += choice.height
        choice.on_choose do |label, value|
          @label = label
          @text.text = label.split(".wav").first
          @value = value
          set_dimensions
          @callback.call @tag, label, value if @callback
        end
      end
    end
  end

  def hide_choices
    @choice_elements.each &:remove
  end
end

