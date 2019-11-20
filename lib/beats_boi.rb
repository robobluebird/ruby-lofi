class BeatsBoi
  attr_reader :bpm
  attr_accessor :sample_path, :sample_repeat, :sample_measures, :loops, :measures, :swing, :sample_length

  def initialize
    @filename = File.join "project", "#{SecureRandom.uuid}.wav"
    @patterns = {}
    @loops = 4
    @bpm = 120
    @measures = 1
    @sample_path = nil
    @sample_repeat = true
    @sample_measures = 1
    @sample_length = 1
    @swing = false
    @bpm_callback = nil
  end

  def on_bpm_change &block
    @bpm_callback = block 
  end

  def write
    t = Tempfile.new ["", ".yml"]

    begin
      t.write "Song:\n"
      t.write "  Tempo: #{@bpm}\n"
      t.write "  Kit:\n"
      t.write "    - sample: #{@sample_path}\n" if @sample_path
      t.write "  Flow:\n"
      t.write "    - loop: x#{@loops}\n"
      t.write "  Swing: 8\n" if @swing
      t.write "\n"
      t.write "loop:\n"
      t.write "  - sample: #{sample_steps}\n" if @sample_path
      t.write patterns
      t.rewind

      `beats --path #{Dir.pwd} #{t.path} #{@filename}`
    ensure
      t.close
      t.unlink
    end

    File.join Dir.pwd, @filename
  end

  def bpm= new_bpm
    @bpm = new_bpm
    @bpm_callback.call @bpm if @bpm_callback
  end

  def sample_steps
    str = "X..............."

    if @sample_measures > 1 && @sample_measures <= @measures 
      str = str + ("................" * (@sample_measures - 1))
      str = str * (@measures / @sample_measures)
      str_mod = @measures % @sample_measures

      if str_mod != 0 && @sample_repeat
        extra = "X..............." + ("................" * (str_mod - 1))
        str = str + extra
      end
    else
      if @sample_repeat
        str = str * @measures
      else
        str = str + ("................" * (@measures - 1))
      end
    end

    str
  end

  def patterns
    all = []

    @patterns.each_pair do |tag, track|
      instrument = track[:instrument]

      next if instrument == "none"

      all << "  - #{instrument}: #{rep_to_steps tag}\n"
    end

    all.join
  end

  def rep_to_steps tag
    track = @patterns[tag]
    str = "................"

    if track
      steps = track[:pattern]

      steps.each do |step|
        str[step - 1] = "X"
      end
    end

    str * @measures
  end

  def set tag, instrument, rep
    @patterns[tag] = {
      :instrument => instrument,
      :pattern => rep
    }
    @patterns
  end
end
