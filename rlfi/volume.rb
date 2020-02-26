class Volume
  def initialize vol = 1.0
    @vol = vol
  end

  def apply buffer, sample_rate, channels
    if channels == 1
      mono_volume buffer
    else
      stereo_volume buffer
    end
  end

  def mono_volume samples
    sample_count = samples.count
    i = 0

    while i < sample_count do
      samples[i] = samples[i] * @vol
      i += 1
    end

    samples
  end

  def stereo_volume samples
    raise "stereo_volume: not yet implemented"
  end
end
