class MovingAverager

  def initialize(size)
    @size = size
    @nums = []
    @sum = 0.0
  end

  def <<(hello)
    @nums << hello
    goodbye = @nums.length > @size ? @nums.shift : 0
    @sum += hello - goodbye
    self
  end

  def average
    if @nums.length < @size
      nil
    else
      @sum / @nums.length
    end
  end
end