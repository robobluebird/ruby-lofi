class Drum
  attr_reader :x, :y, :width, :height, :label
  attr_accessor :enabled

  LABEL_WIDTH = 100

  def initialize attrs = {}
    @tag = attrs[:tag]
    @x = attrs[:x] || 0
    @y = attrs[:y] || 0
    @width = attrs[:width] || 0
    @height = attrs[:height] || 0
    @z = attrs[:z] || 0
    @content = nil
    @pattern = nil
    @choosing = false
    add
  end

  def enabled?
    true
  end

  def contains? x, y
    @x <= x && @x + @width >= x && @y <= y && @y + @height >= y
  end

  def full_width?
    true
  end

  def on_change &block
    @callback = block
  end

  def x= new_x
    @x = new_x
    @content.x = new_x
    @chooser.x = new_x
    @pattern.width = @width - LABEL_WIDTH
    @pattern.x = new_x + @width - @pattern.width
  end

  def y= new_y
    @y = new_y
    @content.y = new_y
    @chooser.y = new_y
    @pattern.y = new_y
  end

  def width= new_width
    @width = new_width
    @pattern.width = new_width - LABEL_WIDTH
    @pattern.x = @x + new_width - @pattern.width
  end

  def mouse_down x, y
    if @chooser.contains? x, y
      @chooser.mouse_down x, y
      @choosing = true
    elsif @pattern.contains? x, y
      @pattern.mouse_down x, y
    end
  end

  def mouse_up x, y
    if @pattern.contains? x, y
      @pattern.mouse_up x, y
    elsif @choosing
      @chooser.mouse_up x, y
    end
  end

  def mouse_move x, y
    @chooser.mouse_move x, y if @choosing
  end

  def remove
    @content.remove
    @chooser.remove
    @pattern.remove
  end

  # ADD THE DRUM CHOOSER

  def add
    if @rendered
      @chooser.add
    else
      raise "disaster strikes" unless Dir.exists? "sounds/samples"

      all_sounds = Dir.entries("sounds/samples")
        .keep_if { |sound| sound.end_with? ".wav" }
        .sort

      all_sounds.unshift "none"

      @chooser = Chooser.new(
        x: @x,
        y: @y,
        z: @z,
        tag: @tag,
        choices: all_sounds.map do |sound|
          {
            label: sound,
            value: sound == "none" ? sound : "sounds/samples/#{sound}"
          }
        end
      )

      @chooser.on_change do |tag, label, value|
        @callback.call @tag, value, @pattern.steps if @callback
      end

      @content = Rectangle.new(
        x: @x,
        y: @y,
        z: @z,
        width: @width,
        height: @height
      )

      @pattern = Pattern.new z: @z

      @pattern.on_change do |steps, measures, beats_per_measure|
        @callback.call @tag, @chooser.value, steps if @callback
      end

      @height = @pattern.height
      @content.height = @height
    end
  end
end
