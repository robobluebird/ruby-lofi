class Composer
  attr_accessor :swing, :loops, :measures_per_sample, :samples_per_loop

  def initialize
    @base = nil
    @sr = nil
    @ch = nil
    @f = nil

    @patterns = {}
    @swing = false
    @loops = 4

    @measures_per_sample = 1
    @samples_per_loop = 1
    @loops = 4

    @output = File.join "project", "#{SecureRandom.uuid}.wav"
  end

  def bpm= new_bpm
    # noop
  end

  def write
    raise "No base sample specified!" if @base.nil?

    b = Blender.new @base, @sr, @ch, @f, @measures_per_sample, @loops

    @patterns.each_pair do |t, p|
      b.add_sample p[:buffer], p[:beat] if p[:active]
    end

    b.write @output
  end

  def set_base filepath
    RubyAudio::Sound.open filepath do |sound|
      @base = RubyAudio::Buffer.float sound.info.frames, 1
      sound.read @base
      @sr = sound.info.samplerate
      @ch = 1
      @f = sound.info.format
    end
  end

  def set_pattern tag, instrument, rep
    # If we have already loaded an instrument for this "tag" then
    # we can perhaps shortcircuit having to re-read a buffer.
    #
    # First, if the "instrument" has been set back to "none" then we
    # set "active" to false. This means that this tag won't be included
    # in the processesing. We keep the instrument, buffer, and beat tho
    #
    # Second, if the instrument we are setting for this tag is the same
    # then that means only the "rep" has changed, e.g. the steps that this
    # pattern plays, so we can set those then return.
    if @patterns[tag]
      if instrument == "none"
        puts "setting #{tag}, inst #{@patterns[tag][:instrument]}, to inactive"
        @patterns[tag][:active] = false
        return
      end

      if @patterns[tag][:instrument] == instrument
        puts "setting #{tag}, inst #{@patterns[tag][:instrument]}, to new beat #{rep}"
        @patterns[tag][:beat] = rep
        return
      end
    end

    # If we are here then an instrument has not been loaded for this "tag"
    # so we'll read the instrument into a buffer and set it into the patterns
    # map

    buffer = nil

    RubyAudio::Sound.open instrument do |sound|
      buffer = RubyAudio::Buffer.float sound.info.frames, 1
      sound.read buffer
    end

    puts "setting new tag #{tag} with instrument #{instrument} and beat #{rep}"
    puts "buffer count = #{buffer.count}"

    @patterns[tag] = {
      :active => true,
      :instrument => instrument,
      :buffer => buffer,
      :beat => rep
    }

    @patterns
  end
end
