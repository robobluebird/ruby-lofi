require "gosu"
require "set"

class Pattern
  attr_reader :x, :y, :w, :h, :editable, :beats

  def initialize x, y, w, h, editable = true, beats = [], constrain = false
    @x = x
    @y = y
    @w = w
    @h = h
    @editable = editable
    @callback = nil

    combined_width_of_checkboxes = 16 * 10
    space_left = @w.to_f - combined_width_of_checkboxes
    gap_width = space_left / 15
    x = 0
    y = @y + ((@h - 10) / 2)

    @beats = Set.new beats

    @checks = Array.new(16).map.with_index do |_,i|
      first_beat_of_prime = constrain && i == 0
      initially_checked = beat_includes?(i + 1) || first_beat_of_prime
      editable = constrain ? initially_checked : @editable

      c = Checkbox.new @x + (i * 10) + (i * gap_width), y, 10, initially_checked, i + 1, editable

      c.hidden = !editable
      c.allow_uncheck = !first_beat_of_prime

      c.on_change do |checked, tag|
        if checked
          @beats.add tag
        else
          @beats.delete tag
        end

        @callback.call @beats if @callback
      end

      c
    end
  end

  def on_change &block
    @callback = block
  end

  def beat_includes? step
    @beats.include? step
  end

  def set_beats beat_array, constrain = false
    @beats.replace beat_array

    @checks.each.with_index do |c, i|
      included = beat_includes? c.tag
      c.enabled = !constrain || included
      c.hidden = !c.enabled?
      c.allow_uncheck = constrain && i == 0
      c.set_checked included, i == @checks.length - 1
    end
  end

  def editable= e
    @editable = !!e
  end

  def editable?
    @editable
  end

  def contains? x, y
    @x <= x && @x + @w >= x && @y <= y && @y + @h >= y
  end

  def mouse_down x, y
    if @some_check = @checks.find { |c| c.contains? x, y }
      @some_check.mouse_down x, y
    end
  end

  def mouse_update x, y
    if @some_check
      @some_check.mouse_update x, y
    end
  end

  def mouse_up x, y
    if @some_check
      @some_check.mouse_up x, y
      @some_check = nil
    end
  end

  def draw
    @checks.each(&:draw)
  end
end
