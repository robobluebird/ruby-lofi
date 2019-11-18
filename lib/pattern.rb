require "set"

class Pattern
  attr_reader :x, :y, :width, :height, :label, :tag
  attr_accessor :enabled

  def initialize opts = {}
    @enabled = true
    @content = nil
    @pattern_steps = []
    @vertical_margin = 5
    @pattern_step_size = 12
    @measures = opts[:measures] || 4
    @beats_per_measure = opts[:beats_per_measure] || 4
    @x = 0
    @y = 0
    @z = opts[:z] || 0
    @width = 0
    @height = @pattern_step_size + @vertical_margin * 2
    @active_steps = Set.new
    @dividers = []
    add
  end

  def steps
    @active_steps
  end

  def contains? x, y
    @content.x <= x && @content.x + @content.width >= x &&
      @content.y <= y && @content.y + @content.height >= y
  end

  def on_change &block
    @callback = block
  end

  def margin
    number_of_steps = @measures * @beats_per_measure
    combined_width_of_steps = number_of_steps * @pattern_step_size
    whitespace = @width - combined_width_of_steps
    whitespace / (number_of_steps + 1)
  end

  def x= new_x
    @x = new_x
    @content.x = new_x

    @pattern_steps.each.with_index do |step, index|
      step.x = @x + (margin * (index + 1)) + (@pattern_step_size * index)
    end

    @dividers.each.with_index do |div, index|
      div.x = @pattern_steps[((index + 1) * 4) - 1].x + @pattern_step_size + 2
    end

  end

  def y= new_y
    @y = new_y
    @content.y = new_y
    @pattern_steps.each { |step| step.y = new_y + @vertical_margin }
    @dividers.each { |div| div.y = new_y }
  end

  def width= new_width
    @width = new_width
    @content.width = new_width

    @pattern_steps.each.with_index do |step, index|
      step.x = @x + (margin * (index + 1)) + (@pattern_step_size * index)
    end

    @dividers.each.with_index do |div, index|
      div.x = @pattern_steps[index * 4].x + margin / 2
    end
  end

  def full_width?
    true
  end

  def mouse_down x, y
    if step = @pattern_steps.find { |p| p.contains? x, y }
      step.mouse_down x, y
    end
  end

  def mouse_up x, y
    if step = @pattern_steps.find { |p| p.contains? x, y }
      step.mouse_up x, y
    end
  end

  def mouse_move x, y
  end

  def remove
    @content.remove
    @pattern_steps.each(&:remove)
    @pattern_steps.clear
    @dividers.each(&:remove)
    @dividers.clear
  end

  def add
    @content = Rectangle.new(
      x: @x,
      y: @y,
      z: @z,
      width: @width,
      height: @height,
      color: "white"
    )

    (@measures * @beats_per_measure).times do |i|
      step = PatternStep.new(
        step_number: i + 1,
        x: @x + (margin * (i + 1)) + (@pattern_step_size * i),
        y: @y + @vertical_margin,
        z: @z,
        radius: @pattern_step_size / 2
      )

      step.on_change do |step_number, status|
        if status
          @active_steps.add step_number
        else
          @active_steps.delete step_number
        end

        @callback.call @active_steps, @measures, @beats_per_measure if @callback
      end

      @pattern_steps << step
    end

    3.times do |i|
      @dividers.push Rectangle.new(
        x: @pattern_steps[((i + 1) * 4) - 1].x + @pattern_step_size + 2,
        y: @y,
        z: @z,
        width: 1,
        height: @pattern_step_size,
        color: "black"
      )
    end
  end
end
