class Effects
  attr_reader :x, :y, :width, :height

  def initialize attrs = {}
    @x = 0
    @y = 0
    @height = 0
    @width = attrs[:width] || 0
    @elements = []
    @sliders = []
    @checks = []
    @choosers = []
    @callback = nil
    add
  end
  
  def on_change &block
    @callback = block
  end

  def mouse_down x, y
    element = @elements.find { |e| e.contains? x, y }
    if element
      element.mouse_down x, y 
      @selected_chooser = element if element.is_a? Chooser
    end
  end

  def mouse_up x, y
    if @selected_chooser
      @selected_chooser.mouse_up x, y
      @selected_chooser = nil
      return
    end
    element = @elements.find { |e| e.contains? x, y }
    element.mouse_up x, y if element
  end

  def mouse_move x, y
    if @selected_chooser
      @selected_chooser.mouse_move x, y
      return
    end
    element = @elements.find { |e| e.contains? x, y }
    element.mouse_move x, y if element
  end

  def x= new_x
    @x = new_x
    @content.x = new_x
    @lines.x = new_x
  end

  def y= new_y
    @y = new_y
    @content.y = new_y
    @lines.y = new_y
  end

  def width= new_width
    @width = new_width
    @content.width = new_width
    @lines.width = new_width
  end

  def full_width?
    true
  end

  def remove
    @lines.remove
    @elements.clear
  end

  def add
    @content = Rectangle.new(
      x: 0,
      y: 0,
      width: 0,
      height: 0
    )

    @lines = VerticalLayout.new(
      width: @width,
      vertical_margin: 10
    )

    add_delay!
    # add_eq!
    add_speed!
    # add_leveller!
    # add_downsample!

    @sliders = @delays + @speeds # @eqs
    @checks = [@delay_check, @speed_check] # @eq_check
    @elements = @sliders + @checks + @choosers

    @x = @lines.x
    @y = @lines.y
    @height = @lines.height
    @width = @lines.width
    @content.width = @lines.width
    @content.height = @lines.height
  end

  def add_downsample!
    @ds_line = HorizontalLayout.new @width

    @ds_line.append Text.new(
      "downsample",
      color: "black",
      font: File.join(__dir__, "fonts", "lux.ttf"),
      size: 14
    )

    @choosers.push Chooser.new(
      tag: "downsample",
      choices: [
        {
          label: "none",
          value: 0
        },
        {
          label: "some",
          value: 1
        },
        {
          label: "a lot",
          value: 2
        }
      ]
    )

    @ds_line.append @choosers[0]
    @lines.append @ds_line
  end

  def add_speed!
    @speed_line = HorizontalLayout.new @width

    @speeds = [
      Slider.new(
        tag: :sample_rate_modifier,
        min: 0,
        max: 2,
        value: 1,
        label: "speed",
        enabled: false,
        show_value: true
      )
    ]

    @speeds.each do |speed_slider|
      speed_slider.on_change do |change|
        @callback.call(speed_slider.tag => change) if @callback
      end
    end

    @speed_check = Checkbox.new label: "speed", checked: false

    @speed_check.on_change do |status|
      @speeds.each do |speed_slider|
        speed_slider.enabled = status
        new_value = status ? speed_slider.value : nil
        @callback.call(speed_slider.tag => new_value) if @callback
      end
    end

    @speed_line.append(@speed_check).append(@speeds.last)
    @lines.append @speed_line
  end

  def add_leveller!
    @lev_check = Checkbox.new label: "loudness", checked: false

    @lev_check.on_change do |status|
    end

    @lines.append @lev_check
  end

  def add_delay!
    @delay_line = HorizontalLayout.new @width

    @delays = [
      Slider.new(
        tag: :delay_rate,
        min: 0,
        max: 1,
        value: 0.5,
        label: "delay factor",
        enabled: false,
        show_value: true
      ),
      Slider.new(
        tag: :decay_rate,
        min: 0,
        max: 1,
        value: 0.5,
        label: "decay factor",
        enabled: false,
        show_value: true
      ),
    ]

    @delays.each do |delay_slider|
      delay_slider.on_change do |change|
        @callback.call(delay_slider.tag => change) if @callback
      end
    end

    @delay_check = Checkbox.new label: "delay", checked: false

    @delay_check.on_change do |status|
      @delays.each do |delay_slider|
        delay_slider.enabled = status
        new_value = status ? delay_slider.value : nil
        @callback.call(delay_slider.tag => new_value) if @callback
      end
    end

    @delay_line.append(@delay_check).append(@delays.first).append(@delays.last)

    @lines.append @delay_line
  end

  def add_eq!
    @eq_line = HorizontalLayout.new @width

    @eqs = [
      Slider.new(tag: :eq_low, min: 0, max: 2, value: 1, label: "low", enabled: false),
      Slider.new(tag: :eq_mid, min: 0, max: 2, value: 1, label: "mid", enabled: false),
      Slider.new(tag: :eq_high, min: 0, max: 2, value: 1, label: "high", enabled: false)
    ]

    @eqs.each do |eq_slider|
      eq_slider.on_change do |change|
        @callback.call(eq_slider.tag => change) if @callback
      end
    end

    @eq_check = Checkbox.new label: "eq", checked: false

    @eq_check.on_change do |status|
      @eqs.each do |eq_slider|
        eq_slider.enabled = status
        new_value = status ? eq_slider.value : nil
        @callback.call(eq_slider.tag => new_value) if @callback
      end
    end

    @eq_line.append(@eq_check).append(@eqs[0]).append(@eqs[1]).append(@eqs[2])
    @lines.append @eq_line
  end
end
