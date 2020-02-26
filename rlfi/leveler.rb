class Leveler
  def initialize passes = 1
    @passes = passes
    @factors = 6
    @limits = [0.0001, 0.0, 0.1, 0.3, 0.5, 1.0]
    @adj_limits = []
    @add_ons = []
    @adj_factors = [0.8, 1.0, 1.2, 1.2, 1.0, 0.8]
    calculate_leveler_factors
  end

  def apply buffer, sample_rate, channels
    level buffer, sample_rate, channels
  end

  def level samples, sample_rate, channels
    if channels == 1
      mono_level samples
    else
      stereo_level samples
    end
  end

  private

  def calculate_leveler_factors
    prev = 0
    add_on = 0.0
    prev_limit = 0.0
    limit = @limits[0]
    @add_ons[0] = add_on
    adj_factor = @adj_factors[0]
    upper_adj_limit = @limits[0] * adj_factor
    prev_adj_limit = upper_adj_limit
    @adj_limits[0] = upper_adj_limit

    i = 1
    while i < @factors do
      prev = i - 1
      adj_factor = @adj_factors[i]
      prev_limit = @limits[prev]
      limit = @limits[i]
      prev_adj_limit = @adj_limits[prev]
      add_on = prev_adj_limit - adj_factor * prev_limit

      @add_ons[i] = add_on
      @adj_limits[i] = adj_factor * limit + add_on

      i += 1
    end
  end

  def mono_level samples
    i = 0
    sample_count = samples.count

    while i < sample_count do
      @passes.times do
        samples[i] = mono_frame samples[i]
      end

      i += 1
    end

    samples
  end

  def stereo_level samples
    raise "stereo_level: not yet implemented"
  end

  def mono_frame frame
    sign = frame < 0.0 ? -1.0 : 1.0
    fabs = frame.abs
    i = 0

    while i < @factors do
      if fabs <= @limits[i]
        frame *= @adj_factors[i]
        frame += @add_ons[i] * sign
        return frame
      end

      i += 1
    end

    0.99 * sign # default return value?
  end

  def stereo_frame frame
    raise "stereo_frame: not yet implemented"
  end
end
