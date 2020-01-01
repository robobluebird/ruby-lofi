# https://stackoverflow.com/questions/5318989/reverb-algorithm

class Delay
  def initialize delay_rate = nil, decay_rate = nil
    @delay_rate = delay_rate || 0.5 # fractions of a second
    @decay_rate = decay_rate || 0.5
  end

  def apply buffer, sample_rate, channels
    delay buffer, sample_rate, channels
  end

  def delay samples, sample_rate, channels
    if channels == 1
      mono_delay(samples, sample_rate)
    else
      stereo_delay(samples, sample_rate)
    end
  end

  def mono_delay samples, sample_rate
    buffer_size = (sample_rate * @delay_rate).to_i
    sample_iter = 0
    effect_iter = sample_iter + buffer_size
    sample_count = samples.count
    while effect_iter < sample_count do
      samples[effect_iter] += samples[sample_iter] * @decay_rate
      samples[effect_iter] = 0.9 if samples[effect_iter] > 1.0
      sample_iter += 1
      effect_iter += 1
    end
    samples
  end

  def stereo_delay samples, sample_rate
    buffer_size = (sample_rate * @delay_rate).to_i
    sample_iter = 0
    effect_iter = sample_iter + buffer_size
    sample_count = samples.count
    while effect_iter < sample_count do
      channel_data = samples[effect_iter]

      channel_data[0] += samples[sample_iter][0] * @decay_rate
      channel_data[1] += samples[sample_iter][1] * @decay_rate
      channel_data[0] = 0.9 if samples[effect_iter][0] > 1.0
      channel_data[1] = 0.9 if samples[effect_iter][1] > 1.0

      samples[effect_iter] = channel_data

      sample_iter += 1
      effect_iter += 1
    end
    samples
  end
end
