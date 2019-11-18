class Files
  attr_reader :y, :x, :width, :height

  HINT_TEXT = "hint: type on the keyboard to name your file"

  def initialize attrs = {}
    @intent = [:open, :save].include?(attrs[:intent]) ? attrs[:intent] : :open
    @file = attrs[:file]
    @x = attrs[:x] || 0
    @y = attrs[:y] || 0
    @width = attrs[:width] || 200
    @height = attrs[:height] || 100
    @color = attrs[:color] || "white"
    @z = attrs[:z] || 0
    @opacity = attrs[:opacity] if attrs[:opacity]
    @border = nil
    @content = nil
    @line = nil
    @line_border = nil
    @text = nil
    @bin = nil
    @bin_border = nil
    @enabled = true
    @full_width = true
    @padding = 0
    @files = []
    @entries = []
    @entry_height = 15
    @max_entries = nil
    @start_index = nil
    @path = Dir.pwd.split("/")
    @path.push attrs[:extra_path] if attrs[:extra_path]
    @path[0] = "/"
    @input = ""
    @keys = []
    @shifted = false
    @first_click = nil
    @choose_callback = nil
    @export_callback = nil
    add
  end

  def on_cancel &block
    @button2.on_click(&block)
  end

  def on_choose &block
    @choose_callback = block
  end

  def on_export &block
    @export_callback = block
  end

  def mouse_down x, y
    if button = [@button1, @button2].find { |b| b.contains? x, y }
      button.mouse_down x, y
    end
  end

  def mouse_move x, y
    entry = @entries.find do |e|
      box = e[:box]
      box.contains? x, y
    end

    @entries.each do |e|
      e[:box].color = "white"
      e[:text].color = "black"
    end

    if entry
      entry[:box].color = "black"
      entry[:text].color = "white"
    end
  end

  def key_down key
    return unless @intent == :save

    @keys.push key
  end

  def key_up key
    return unless @intent == :save

    @keys.delete key

    if key == "backspace"
      @input = @input[0...-1]
      @button1.enabled = @input.length == 0
    elsif key.include? "shift"
      if !@keys.find { |k| k.include? "shift" }
        @shifted = !@shifted
      end
    elsif key.length > 1
      return
    elsif /[a-zA-Z0-9\._\-]/.match? key
      @input += if @keys.find { |k| k.include? "shift" }
                  if key == "-"
                    "_"
                  elsif key == "."
                    "."
                  else
                    key.upcase
                  end
                else
                  key
                end
      @button1.enabled = @input.length > 0
    end 
    render_text
  end

  def render_text
    if @input.empty?
      @text.text = HINT_TEXT
    else
      @text.text = @input
    end
  end

  def navigate path_segment
    if path_segment == ".."
      if @path.length > 1
        @path.pop
      end
    else
      @path.push path_segment
    end

    load_directory_contents
    populate_bin
  end

  def maybe_open filepath, filename
    begin
      RubyAudio::Sound.open filepath do |sound|
        path = "project/#{filename}"
        `cp #{filepath} #{path}`
        @choose_callback.call path if @choose_callback
      end
    rescue
      "bad file...wavs only"
    end
  end

  def mouse_up x, y
    if @first_click && Time.now.to_f - @first_click < 0.20
      if entry = @entries.find { |e| e[:box].contains? x, y } 
        text = entry[:text].text

        if text.end_with?("/")
          navigate text[0...-1]
        elsif text == ".."
          navigate text
        else
          if @intent == :open
            maybe_open File.join(*@path, text), text
          end
        end
      end

      @first_click = nil
    elsif @content.contains? x, y
      if button = [@button1, @button2].find { |b| b.contains? x, y }
        button.mouse_up x, y
      else
        @first_click = Time.now.to_f
      end
    end 
  end

  def mouse_scroll dx, dy, x, y
    return if @files.count <= @max_entries.floor

    change = if dy > 0
               [dy, @files.count - (@start_index + @max_entries)].min
             else
               [dy, 0 - @start_index].max
             end

    return if change == 0

    @start_index += change

    populate_bin
  end

  def populate_bin
    if @entries.empty?
      x = @bin.x
      y = @bin.y
      y_offset = 0
      @max_entries.times do
        @entries << {
          box: Rectangle.new(
            x: x,
            y: y + y_offset,
            width: @bin.width,
            height: @entry_height,
            z: @z + 1
          ),
          text: Text.new(
            "",
            x: x,
            y: y + y_offset,
            font: File.join(__dir__, "fonts", "lux.ttf"),
            size: 12,
            z: @z + 1,
            color: "black"
          )
        }
        y_offset += @entry_height
      end
    end

    possible_index = @start_index + @max_entries - 1
    furthest = @files.count - 1
    end_index = possible_index > furthest ? furthest : possible_index
    subset = @files[@start_index..end_index]

    @max_entries.times do |index|
      if subset[index]
        @entries[index][:text].text = subset[index]
      else
        @entries[index][:text].text = ""
      end
    end
  end

  def load_directory_contents
    @files = Dir.entries(File.join(*@path))
    @files.map! do |file|
      if (file.start_with?(".") && file != "..") ||
          (file == ".." && @path.length == 1)
        nil
      elsif File.directory?(File.join(*@path, file)) && file != ".."
        file + "/"
      else
        file
      end
    end.compact!.sort!
    @start_index = 0
    @files.length
  end

  def export
    name = @text.text
    path = File.join(*@path, "#{name}.wav")

    if name.length > 0
      File.open(path, "w") do |f|
        f.write File.read @file
      end

      @export_callback.call if @export_callback
    end
  end

  def x= new_x
    @x = new_x
    @border.x = new_x - 2
    @content.x = new_x
    @line.x = new_x + @padding
    @line_border.x = @line.x - 2
    @text.x = new_x + @padding
    @bin.x = new_x + @padding
    @bin_border.x = @bin.x - 2
    @button1.x = @x + @width -
      (@button1.width + @padding + @button2.width + @padding)
    @button2.x = @x + @width -
      (@button2.width + @padding)
    @entries.each { |entry| entry[:box].remove; entry[:text].remove }
    @entries.clear
    populate_bin
  end

  def line_height
    if @intent == :save
      @line.height + @padding
    else
      0
    end
  end
  
  def y= new_y
    @y = new_y
    @border.y = new_y - 2
    @content.y = new_y
    @line.y = new_y + @padding
    @line_border.y = @line.y - 2
    @text.y = new_y + @padding
    @bin.y = new_y + @padding + line_height
    @bin_border.y = @bin.y - 2


    # padding is set to zero, always add 20 to space button
    @button1.y = @y + @padding + line_height + @bin.height + 20
    @button2.y = @y + @padding + line_height + @bin.height + 20

    @entries.each { |entry| entry[:box].remove; entry[:text].remove }
    @entries.clear
    populate_bin
  end

  def width= new_width
    @width = new_width
    @border.width = new_width + 4
    @content.width = new_width
    @line.width = new_width - @padding * 2
    @line_border.width = @line.width + 4
    @bin.width = new_width - @padding * 2
    @bin_border.width = @bin.width + 4
    @button1.x = @x + @width -
      (@button1.width + @padding + @button2.width + @padding)
    @button2.x = @x + @width -
      (@button2.width + @padding)
    @entries.each { |entry| entry[:box].remove; entry[:text].remove }
    @entries.clear
    populate_bin
  end

  def enabled= status
    @enabled = status
  end

  def full_width?
    @full_width
  end

  def remove
    @border.remove
    @content.remove
    @line.remove
    @line_border.remove
    @text.remove
    @bin.remove
    @bin_border.remove
    @button1.remove
    @button2.remove
    @entries.each { |entry| entry[:box].remove; entry[:text].remove }
  end

  def add
    @border = Rectangle.new(
      x: @x - 2,
      y: @y - 2,
      width: @width + 4,
      height: @height + 4,
      color: "black",
      z: @z
    )

    @border.opacity = 0

    @content = Rectangle.new(
      x: @x,
      y: @y,
      width: @width,
      height: @height,
      color: @color,
      z: @z
    )

    @line = Rectangle.new(
      color: "white",
      x: @x + @padding,
      y: @y + @padding,
      width: @width - @padding * 2,
      height: 25,
      z: @z + 1
    )

    @line_border = Rectangle.new(
      color: "black",
      x: @line.x - 2,
      y: @line.y - 2,
      width: @line.width + 4,
      height: @line.height + 4,
      z: @z
    )

    if @intent == :open
      @line.remove
      @line_border.remove
    end

    @text = Text.new(
      "",
      x: @x + @padding,
      y: @y + @padding,
      font: File.join(__dir__, "fonts", "lux.ttf"),
      size: 14,
      z: @z + 1,
      color: "black"
    )

    @bin = Rectangle.new(
      color: "white",
      x: @x + @padding + line_height,
      y: @y + @padding,
      width: @width - @padding * 2,
      height: 100,
      z: @z + 1
    )

    @bin_border = Rectangle.new(
      color: "black",
      x: @bin.x - 2,
      y: @bin.y - 2,
      width: @bin.width + 4,
      height: @bin.height + 4,
      z: @z
    )

    @button1 = Button.new(
      width: 50,
      height: 25,
      y: @y + @padding + line_height + @bin.height + @padding,
      label: @intent == :save ? "export" : "open",
      enabled: !(@intent == :save),
      z: @z + 1,
    )

    if @intent == :open
      @button1.enabled = false
      @button1.opacity = 0
    else
      @button1.on_click do
        export 
      end
    end

    @button2 = Button.new(
      width: 50,
      height: 25,
      y: @y + @padding + line_height + @bin.height + @padding,
      label: "cancel",
      enabled: true,
      z: @z + 1
    )

    @button1.x = @x + @width -
      (@button1.width + @padding + @button2.width + @padding)

    @button2.x = @x + @width -
      (@button2.width + @padding)

    lh = @intent == :save ? @line.height / 2 : 0
    @text.y = @line.y + lh - @text.height / 2

    @height = @padding + line_height + @bin.height + @padding +
      @button1.height + 20 # padding is set to zero, always add 20 to space button
    @content.height = @height
    @border.height = @height + 4

    @max_entries = (@bin.height.to_f / @entry_height).floor

    load_directory_contents
    populate_bin
    render_text
  end
end
