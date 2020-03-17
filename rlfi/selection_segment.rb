class SelectionSegment
  attr_reader :coords, :indicies

  def initialize coords, indicies
    @coords, @indicies = coords, indicies
  end
end
