class Stitch
  attr_reader :x, :y, :width, :height, :files

  def initialize attrs = {}
    @x = 0
    @y = 0
    @width = attrs[:width]
    @height = 0
    @filepaths = []
    @fileboxes = []
    @files = nil
    @layout = nil
    @cancel_callback = nil
    @sample_rate = nil
    @format = nil
    add
  end

  def on_cancel &block
    @cancel_callback = block
  end

  def mouse_down x, y
    e = @layout.element_at x, y
    e.mouse_down x, y if e && e.respond_to?(:mouse_down)
  end

  def mouse_up x, y
    e = @layout.element_at x, y
    e.mouse_up x, y if e && e.respond_to?(:mouse_up)
  end

  def mouse_move x, y
    e = @layout.element_at x, y
    e.mouse_move x, y if e && e.respond_to?(:mouse_move)
  end

  def mouse_scroll dx, dy, x, y
    e = @layout.element_at x, y
    e.mouse_scroll dx, dy, x, y if e && e.respond_to?(:mouse_scroll)
  end

  def full_width?
    true
  end

  def x= new_x
    @x = new_x
    @layout.x = new_x
  end

  def y= new_y
    @y = new_y
    @layout.y = new_y
  end

  def width= new_width
    @width = new_width
    @layout.width = new_width
    @button.x = @x + @width - @button.width
    @button2.x = @x + @width - @button2.width
  end

  def stitch
    total_buffer_size = 0

    sound_buffers = @filepaths.map do |filepath|
      RubyAudio::Sound.open filepath do |sound|
        @sample_rate = sound.info.samplerate
        @format = sound.info.format
        buffer = sound.read :float, sound.info.frames
        total_buffer_size += buffer.count
        buffer
      end
    end

    final_buffer = RubyAudio::Buffer.float total_buffer_size, 1

    overall_index = 0
    sound_buffers.each do |buffer|
      local_index = 0
      buffer_count = buffer.count
      while local_index < buffer_count do
        final_buffer[overall_index] = buffer[local_index]
        local_index += 1
        overall_index += 1
      end
    end

    info = RubyAudio::SoundInfo.new(
      channels: 1,
      samplerate: @sample_rate,
      format: @format
    )

    dir = File.join Dir.pwd, "stitches"

    if !Dir.exists? dir
      Dir.mkdir dir
    end

    path = File.join dir, "stitch1.wav"

    stitch_index = 1
    while File.exists? path
      stitch_index += 1
      path = File.join dir, "stitch#{stitch_index}.wav"
    end

    out = RubyAudio::Sound.open path, "w", info

    out.write final_buffer

    out.close

    @cancel_callback.call if @cancel_callback
  end

  def add_file filepath
    @filepaths.push filepath
    show_files
  end

  def remove_files
    i = 0
    while i < @fileboxes.count do
      @layout.delete_at 1
      i += 1
    end 
    @fileboxes.each(&:remove)
    @fileboxes.clear
  end

  def show_files
    remove_files

    @fileboxes = @filepaths.map.with_index do |filepath, index|
      Text.new(
        "#{index + 1}. #{filepath.split("/").last}",
        x: @x,
        y: @y,
        font: File.join(__dir__, "fonts", "lux.ttf"),
        size: 14,
        color: "black"
      )
    end

    @fileboxes.reverse.each do |filebox|
      @layout.insert 1, filebox
    end

    e = @fileboxes.count > 0
    @button.enabled = e
    @button2.enabled = e
    @height = @layout.height
  end

  def pop_file
    @filepaths.pop
    show_files
  end

  def add
    @layout = VerticalLayout.new(
      width: @width,
      horizontal_margin: 10,
      vertical_margin: 10
    )

    @files = Files.new intent: :open

    @files.on_cancel do
      @cancel_callback.call if @cancel_callback
    end

    @files.on_choose do |filepath|
      add_file filepath
    end

    @button = Button.new(
      label: "stitch",
      x: @x + @width - 50,
      height: 25,
      width: 50,
      enabled: false
    )
    
    @button.on_click do
      stitch
    end

    @button2 = Button.new(
      label: "pop last",
      x: @x + @width - 50,
      height: 25,
      width: 50,
      enabled: false
    )

    @button2.on_click do
      pop_file
    end

    @layout.append(@files).append(@button).append(@button2)

    show_files

    self
  end

  def remove
    remove_files
    @layout.remove
  end
end
