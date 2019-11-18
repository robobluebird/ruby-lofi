class Rando
  def apply samples, sample_rate, channels
    sample_count = samples.count
    i = 0
    while i < sample_count do
      method = Random.rand(2).zero? ? :+ : :-
      samples[i] = samples[i].send method, Random.rand(0.01)
      if samples[i] > 0
        samples[i] = 1.0 if samples[i] > 1.0
      elsif samples[i] < 0
        samples[i] = -1.0 if samples[i] < -1.0
      end
      i += 1
    end
    samples
  end
end
