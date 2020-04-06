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
    @measures = 4
    @drum_width = @w / 16
    @measure_width = @w / @measures
    @subdiv_width = @measure_width / 16 # 16 measures of 16th notes
    @segment_height = 20
    @timeline_selections = []
    @beats = []
    @beats_added
  end

  def add_beat_selections
    return if @beats.any?

    filenames = %w(808_kick.wav 808_snare.wav 808_hhc.wav)
    colors = [Gosu::Color::AQUA, Gosu::Color::YELLOW, Gosu::Color::FUCHSIA]

    s = Selection.new(nil, nil, nil, nil, 1.0, 0.0, 0.0, 0, 1.0)
    s.color = Gosu::Color::BLACK

    t = TimelineSelection.new(next_index, s, @measure_width)
    t.synthetic_width = @measure_width

    @timeline_selections.push(t).tap { @h += 20 }

    filenames.each.with_index do |filename, i|
      buffer, sample_rate, channels = nil, nil, 1

      RubyAudio::Sound.open filename do |sound|
        buffer = RubyAudio::Buffer.float sound.info.frames, channels
        sample_rate = sound.info.samplerate
        sound.read buffer
      end

      selection = Selection.new(
        buffer,
        filename,
        sample_rate,
        channels,
        1.0, # speed
        0.0, # delay
        0.0, # decay
        0,   # level
        1.0  # volume
      )

      selection.color = colors[i]

      @timeline_selections.push(
        TimelineSelection.new(next_index, selection, @drum_width, [], true)
      ).tap { @h += 20 }
    end

    @beats_added = true

    self
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

  def delete selection
    ts = @timeline_selections.find { |t| t.selection == selection }
    tsi = ts.index
    @timeline_selections.delete ts

    @h -= 20

    if tsi > 0
      @timeline_selections.each do |tss|
        if tss.index > tsi
          tss.index -= 1
          
          if tss.index == 0
            tss.segment_width = @measure_width
          end
        end
      end
    end
  end

  def add_base selection
    raise "Already set base in timeline" if base?

    @timeline_selections.push(TimelineSelection.new(0, selection, @measure_width)).tap { @h += 20 }

    add_beat_selections if !@beats_added

    self
  end

  def add_selection selection
    if !base?
      add_base selection
      return
    end

    @timeline_selections.each do |ts|
      if ts.index >= 1
        ts.index += 1
      end
    end

    @timeline_selections.insert(
      1,
      TimelineSelection.new(1, selection, @subdiv_width)
    ).tap { @h += 20 }
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

    x_offset = 0
    while x_offset + selection_info.segment_width < adj_x do
      x_offset += selection_info.segment_width
    end

    existing_segment = selection_info.segments.find do |s|
      s.coords.x <= x && s.coords.x + s.coords.w > x
    end

    if existing_segment
      selection_info.segments.delete existing_segment
    elsif selection_info.synthetic_width
      draw_width = selection_info.synthetic_width

      total_buffer_size = base.selection.buffer.count * @measures

      index_in_total_buffer = ((x_offset.to_f / @w) * total_buffer_size).floor
      
      coords = Coords.new x_offset, y_offset + @y, draw_width, @segment_height

      selection_info.segments.push SelectionSegment.new coords, index_in_total_buffer
    else
      buffer_count = selection_info.selection.buffer.count

      draw_width, total_buffer_size = nil, nil

      if selection_info.drum?
        draw_width = @drum_width
        total_buffer_size = base.selection.buffer.count
      else
        draw_width = (buffer_count.to_f / base.selection.buffer.count) * @measure_width
        total_buffer_size = base.selection.buffer.count * @measures
      end

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

    @timeline_selections.count.times do |i|
      color = i % 2 == 0 ? Gosu::Color.argb(0x66_808080) : Gosu::Color.argb(0x33_808080)
      Gosu::draw_rect @x, y, @w, @segment_height, color
      y += @segment_height
    end

    y = @y

    @timeline_selections.sort_by { |t| t.index }.each do |selection|
      selection.segments.each do |segment|
        c = segment.coords
        Gosu::draw_rect c.x, y, c.w, c.h, selection.selection.primary_color
      end

      y += @segment_height
    end
  end
end
