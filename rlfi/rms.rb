class RMS
  def initialize slots
    @slots = slots
  end

  def apply samples, sample_rate, channels
    group_size = (samples.count / @slots).floor

    samples.each_slice(group_size).inject([]) do |memo, sample_slice|
      memo.push rms sample_slice, channels
    end
  end

  def rms samples, channels
    channels == 1 ? mono_rms(samples) : stereo_rms(samples)
  end

  def mono_rms samples
    i = 0
    max = 0
    min = 0
    sum = 0

    while i < samples.count
      max = samples[i] if samples[i] > max
      min = samples[i] if samples[i] < min
      sum += samples[i] * samples[i]
      i += 1
    end 

    [
      Math.sqrt(sum / samples.count).round(3),
      max.round(3),
      min.round(3),
    ]
  end

  def stereo_rms samples
    i = 0
    max = [0, 0]
    min = [0, 0]
    sum = [0, 0]

    while i < samples.count
      # left channel
      max[0] = samples[i][0] if samples[i][0] > max[0]
      min[0] = samples[i][0] if samples[i][0] < max[0]
      sum[0] += samples[i][0] * samples[i][0]
      # right channel
      max[1] = samples[i][1] if samples[i][1] > max[1]
      min[1] = samples[i][1] if samples[i][1] < max[1]
      sum[1] += samples[i][1] * samples[i][1]
      i += 1
    end 

    [
      [
        Math.sqrt(sum[0] / samples.count).round(3),
        Math.sqrt(sum[1] / samples.count).round(3)
      ],
      max.map { |channel| channel.round(3) },
      min.map { |channel| channel.round(3) },
    ]
  end
end
