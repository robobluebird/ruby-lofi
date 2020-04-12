class SelectionSegment
  attr_accessor :coords, :indicies, :original_x

  def initialize original_x, coords, indicies
    @original_x, @coords, @indicies = original_x, coords, indicies
  end
end
