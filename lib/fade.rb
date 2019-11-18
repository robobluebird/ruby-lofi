class Fade
  def initialize in_or_out = :in
    @direction = in_or_out
  end

  def apply samples, sample_rate, channels
    if channels == 1
      fade_mono samples
    else
      fade_stereo samples
    end
  end

  def fade_mono samples
    i = 0
    sample_count = samples.count
    while i < sample_count
      percentage_fade = i / sample_count.to_f
      percentage_fade = 1 - percentage_fade if @direction == :out
      samples[i] = samples[i] * percentage_fade
      i += 1
    end
    samples
  end

  def fade_stereo samples
    i = 0
    sample_count = samples.count
    while i < sample_count
      percentage_fade = i / sample_count.to_f
      percentage_fade = 1 - percentage_fade if @direction == :out
      samples[i][0] = samples[i][0] * percentage_fade
      samples[i][1] = samples[i][1] * percentage_fade
      i += 1
    end
    samples
  end
end
