# https://stackoverflow.com/questions/12469361/java-algorithm-for-normalizing-audio

class Normalize
  def apply buffer, sample_rate, channels
    normalize buffer
  end

  def normalize samples
    # get the largest positive or negative value in samples
    real_max = samples.max_by { |sample| sample.abs }.abs

    # float samples, so max should be +/-1.0
    target_max = 1.0

    # target maximum is x % of real maximum
    reduction_max = 1 - (target_max / real_max)

    i = 0
    sample_count = samples.count # count is a slow op for RubyAudio::Buffer
    while i < sample_count do
      # given the ratio between the current sample value and the
      # maximum, multiply by the inverse ratio of target to maximum
      factor = reduction_max * (samples[i].abs / real_max)

      # reduce (or magnify) the sample by the inverse?
      samples[i] = (1 - factor) * samples[i]

      i += 1
    end

    samples
  end
end
