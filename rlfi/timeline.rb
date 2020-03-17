require_relative "timeline_selection"
require_relative "selection_segment"
require_relative "coords"

class Timeline
  attr_reader :selections
  attr_accessor :x, :y, :w, :h

  def initialize x, y, w
    @x = x
    @y = y
    @w = w
    @h = 0
    @measure_width = @w / 16
    @subdiv_width = @measure_width / 16 # 16 measures of 16th notes
    @segment_height = 20
    @timeline_selections = []
  end

  def on_change &block
    @callback = block
  end

  def base?
    base
  end

  def contains? x, y
    @x <= x && @x + @w >= x && @y <= y && @y + @h >= y
  end

  def base
    @timeline_selections.find { |s| s.base? }
  end

  def next_index
    @timeline_selections.map { |s| s.index }.sort.last + 1
  end

  def add_base selection
    if base?
      base.index = next_index
      base.base = false
    end

    @timeline_selections.push(TimelineSelection.new(true, 0, selection, @measure_width)).tap { @h += 20 }
  end

  def add_selection selection
    @timeline_selections.push(TimelineSelection.new(false, next_index, selection, @subdiv_width)).tap { @h += 20 }
  end

  def mouse_down x, y
    @mousing = true
  end

  def mouse_update x, y
  end

  def mouse_up x, y
    @mousing = false

    adj_y = y - @y
    adj_x = x - @x

    y_index = 0
    y_offset = 0
    while y_offset + @segment_height < adj_y do
      y_offset += @segment_height
      y_index += 1
    end

    selection_info = @timeline_selections.find { |s| s.index == y_index }

    unless selection_info
      puts "couldn't find selection row with index == y_index. y_offset is #{ y_offset }, y_index is #{ y_index }"
      return
    end

    x_index = 0
    x_offset = 0
    while x_offset + selection_info.segment_width < adj_x do
      x_offset += selection_info.segment_width
      x_index += 1
    end

    existing_segment = selection_info.segments.find do |s|
      s.coords.x <= x && s.coords.x + s.coords.w > x
    end

    if existing_segment
      selection_info.segments.delete existing_segment
    else
      buffer_count = selection_info.selection.buffer.count

      draw_width = (buffer_count.to_f / base.selection.buffer.count) * @measure_width

      total_buffer_size = base.selection.buffer.count * 16

      index_in_total_buffer = ((x_offset.to_f / @w) * total_buffer_size).floor

      last_index_in_total_buffer = [(index_in_total_buffer + buffer_count), total_buffer_size].min

      indicies = index_in_total_buffer...last_index_in_total_buffer

      coords = Coords.new x_offset, y_offset + @y, draw_width, @segment_height

      selection_info.segments.push SelectionSegment.new coords, indicies
    end

    @callback.call @timeline_selections if @callback
  end

  def draw
    y = @y

    (@h / @segment_height).times do |i|
      color = i % 2 == 0 ? Gosu::Color.argb(0x66_808080) : Gosu::Color.argb(0x33_808080)
      Gosu::draw_rect @x, y, @w, @segment_height, color
      y += @segment_height
    end

    @timeline_selections.each do |selection|
      selection.segments.each do |segment|
        c = segment.coords
        Gosu::draw_rect c.x, c.y, c.w, c.h, selection.selection.primary_color
      end
    end
  end
end
