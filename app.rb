require "ruby2d"
require "ruby-audio"
require "tempfile"
require "securerandom"

DIR = File.expand_path(File.dirname(__FILE__))

Dir.entries("#{DIR}/lib").each do |entry|
  if entry.include? ".rb"
    name = entry.split(".rb").first
    require "#{DIR}/lib/#{name}"
  end
end

class Ruby2D::Text
  def full_width?
    false
  end
end

def intro
  @layout.remove

  h = Heading.new label: "ruby lofi - make a simple beat"

  # (screen width - edge margin * 2 - inner margins * 1) / 2
  button_width = (640 - (10 * 2) - (20 * 1)) / 2

  button1 = Button.new label: "new", width: button_width, height: 25
  button2 = Button.new label: "stitch", width: button_width, height: 25

  hbl = HorizontalLayout.new @layout.width

  hbl.append(button1).append(button2)

  button1.on_click do
    @layout.remove

    hb = Heading.new label: "choose a file"

    files = Files.new intent: :open

    files.on_cancel do
      intro
    end

    files.on_choose do |filepath|
      project filepath
    end

    @layout.append(hb).append(files)
  end

  button2.on_click do
    @layout.remove
    
    s = Stitch.new width: get(:width)

    s.on_cancel do
      intro
    end

    @layout.append s
  end

  @layout.append(h).append(hbl)
end

def project filepath
  @layout.remove

  v = VisualizedTrack.new filepath

  v.on_change do |path, bpm|
    @beat.sample_path = path
    @beat.bpm = bpm
    enable_build
  end

  e = Effects.new

  e.on_change do |opts|
    v.effect opts
  end

  h1 = Heading.new label: "sample editor"
  h2 = Heading.new label: "sample effects"
  h3 = Heading.new label: "make a beat"
  h4 = Heading.new label: "track settings"
  h5 = Heading.new label: "track control"

  d1 = Drum.new z: 20, :tag => 1

  d1.on_change do |tag, instrument, steps|
    @beat.set tag, instrument, steps
    enable_build
  end

  d2 = Drum.new z: 20, :tag => 2

  d2.on_change do |tag, instrument, steps|
    @beat.set tag, instrument, steps
    enable_build
  end

  d3 = Drum.new z: 20, :tag => 3

  d3.on_change do |tag, instrument, steps|
    @beat.set tag, instrument, steps
    enable_build
  end

  d4 = Drum.new z: 20, :tag => 4

  d4.on_change do |tag, instrument, steps|
    @beat.set tag, instrument, steps
    enable_build
  end

  button_layout = HorizontalLayout.new @layout.width

  swing_checkbox = Checkbox.new label: "swing", checked: false

  swing_checkbox.on_change do |status|
    @beat.swing = status
    enable_build
  end

  sample_length_slider = Slider.new(
    min: 1,
    max: 4,
    value: 1,
    label: "measures in sample",
    show_value: true,
    round_value: true
  )

  measures = Slider.new(
    label: "measures per loop",
    min: 1,
    max: 4,
    round_value: true,
    value: @beat.measures,
    show_value: true
  )

  sample_length_slider.on_change do |value|
    @beat.sample_length = value
    v.length = value
    @beat.bpm = v.bpm
    @beat.sample_measures = value

    if measures.value < value
      measures.value = value
      @beat.measures = value
    end

    enable_build
  end

  loops = Slider.new(
    label: "loops in track",
    min: 1,
    max: 4,
    round_value: true,
    value: @beat.loops,
    show_value: true
  )

  measures.on_change do |value|
    @beat.measures = value

    if sample_length_slider.value > value
      sample_length_slider.value = value 
      @beat.sample_length = value
      v.length = value
      @beat.bpm = v.bpm
      @beat.sample_measures = value
    end

    enable_build
  end

  loops.on_change do |value|
    @beat.loops = value
    enable_build
  end
  
  bpm_layout = HorizontalLayout.new @layout.width

  @beat.on_bpm_change do |new_bpm, bad_bpm|
    @bpm_label.text = "bpm: #{bad_bpm || new_bpm.floor}"
  end

  @bpm_label = Text.new(
    "",
    color: "black",
    font: File.join(DIR, "lib", "fonts", "lux.ttf"),
    size: 14
  )

  bpm_layout.append(@bpm_label)

  # screen width - edge margin * 2 - inner margins * 2 / 3
  button_width = (640 - 20 - 80) / 5

  @play_button = Button.new label: "play", height: 25, width: button_width
  @play_button.on_click do
    play
  end

  @stop_button = Button.new label: "stop", height: 25, width: button_width
  @stop_button.on_click do
    stop
  end

  @build_button = Button.new enabled: false, label: "build", height: 25, width: button_width
  @build_button.on_click do
    @path = @beat.write
    disable_build
  end

  @export_button = Button.new label: "save", height: 25, width: button_width
  @export_button.on_click do
    f = Files.new intent: :save, file: @path

    @layout.insert 0, f

    f.on_cancel do
      @layout.delete_at 0
    end

    f.on_export do
      @layout.delete_at 0
    end
  end

  @new_button = Button.new label: "new", height: 25, width: button_width
  @new_button.on_click do 
    @layout.remove

    hb = Heading.new label: "choose a file"

    files = Files.new intent: :open

    files.on_cancel do
      intro
    end

    files.on_choose do |filep|
      project filep
    end

    @layout.append(hb).append(files)
  end

  button_layout
    .append(@build_button)
    .append(@play_button)
    .append(@stop_button)
    .append(@export_button)
    .append(@new_button)

  @layout
    .append(h1)
    .append(v)
    .append(h2)
    .append(e)
    .append(h3)
    .append(d1)
    .append(d2)
    .append(d3)
    .append(d4)
    .append(h4)
    .append(swing_checkbox)
    .append(sample_length_slider)
    .append(measures)
    .append(loops)
    .append(bpm_layout)
    .append(h5)
    .append(button_layout)
end

def stop
  if @path && @pid
    Process.kill "HUP", @pid
    @pid = nil
    @playing = false
    @play_button.deactivate
  end
end

def play
  if @path
    stop if @playing
    @pid = spawn "play -q #{@path}"
    @playing = true
    @play_button.activate
  end
end

def enable_build
  stop
  @build_button.enabled = true
  @play_button.deactivate
  @play_button.enabled = false
  @stop_button.enabled = false
  @export_button.enabled = false
end

def disable_build
  @build_button.enabled = false
  @play_button.enabled = true
  @stop_button.enabled = true
  @export_button.enabled = true
end

begin
  FileUtils.rm_rf "project"
  FileUtils.mkdir "project"

  @path = nil
  @pid = nil
  @playing = false
  @clicked = nil
  @hovered = nil
  @layout = VerticalLayout.new(
    width: get(:width),
    horizontal_margin: 10,
    vertical_margin: 10
  )
  @beat = BeatsBoi.new
  @beat.measures = 4
  @path = nil
  @ticks = 0
  @bge = :none

  def clicked_element x, y
    @layout.element_at x, y
  end

  on :mouse_down do |event|
    @clicked = clicked_element event.x, event.y
    @clicked.mouse_down event.x, event.y if @clicked
  end

  on :mouse_up do |event|
    @clicked.mouse_up event.x, event.y if @clicked
    @clicked = nil
  end

  on :mouse_move do |event|
    if @clicked
      @clicked.mouse_move event.x, event.y
    elsif @hovered = @layout.element_at(event.x, event.y)
      @hovered.mouse_move event.x, event.y
    else
      @hovered = nil
    end
  end

  on :mouse_scroll do |event|
    if @hovered && @hovered.respond_to?(:mouse_scroll)
      @hovered.mouse_scroll event.delta_x, event.delta_y, get(:mouse_x), get(:mouse_y)
    end
  end

  on :key_down do |event|
    if files = @layout.elements.find { |e| e.is_a? Files }
      files.key_down event.key
    elsif track = @layout.elements.find { |e| e.is_a? VisualizedTrack }
      track.key_down event.key
    end
  end

  on :key_up do |event|
    if files = @layout.elements.find { |e| e.is_a? Files }
      files.key_up event.key
    elsif track = @layout.elements.find { |e| e.is_a? VisualizedTrack }
      track.key_up event.key
    end
  end

  set background: "white"
  set title: "lofi ruby"
  set height: 625

  intro

  show
rescue Exception => e
  puts e.message
  puts e.backtrace
  @layout.remove
end
