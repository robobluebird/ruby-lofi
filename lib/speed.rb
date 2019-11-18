# hevi.info/do-it-yourself/interpolating-and-array-to-fit-another-size/

class Speed
  def initialize percent_change
    @percent_change = percent_change
  end

  def apply buffer, sample_rate, channels
    if channels == 1
      speed_mono buffer, channels
    else
      speed_stereo buffer, channels
    end
  end

  def speed_mono samples, channels
    new_size = samples.count / @percent_change
    interpolate_mono samples, new_size.to_i, channels
  end

  def speed_stereo samples, channels
    new_size = samples.count / @percent_change
    interpolate_stereo samples, new_size.to_i, channels
  end

  def interpolate_mono data, new_size, channels
    new_data = RubyAudio::Buffer.float new_size, channels
    spring_factor = (data.count - 1).to_f / (new_size - 1)
    new_data[0] = data[0]
    i = 0
    while i < new_size - 1 do
      temp = i * spring_factor
      before = temp.floor
      after = temp.ceil
      at_point = temp - before
      new_data[i] = linear_interpolate data[before], data[after], at_point
      i += 1
    end
    new_data[new_size - 1] = data[data.count - 1]
    new_data
  end

  def interpolate_stereo data, new_size, channels
    new_data = RubyAudio::Buffer.float new_size, channels
    spring_factor = (data.count - 1).to_f / (new_size - 1)
    new_data[0] = data[0]
    i = 0
    while i < new_size - 1 do
      temp = i * spring_factor
      before = temp.floor
      after = temp.ceil
      at_point = temp - before

      # left channel
      new_data[i][0] = linear_interpolate data[before][0], data[after][0], at_point

      # right channel
      new_data[i][1] = linear_interpolate data[before][1], data[after][1], at_point

      i += 1
    end
    new_data[new_size - 1] = data[data.count - 1]
    new_data
  end

  def linear_interpolate before, after, at_point
    before + (after - before) * at_point
  end
end
