
class LowFrequencyPercentage
  def initialize(user)
    @user = user
    @sum_threshold = 100
    @quantity_threshold = 3
    @epsilon = 0.01
  end

  def set_sum_threshold(value)
    @sum_threshold = value
  end

  def set_quantity_threshold(value)
    @quantity_threshold = value
  end

  def set_epsilon(epsilon)
    @epsilon = epsilon
  end

  def is_infrequent?(locality)
    sum = @user.frequencies.map { |m| m.value}.reduce :+
    if sum < @sum_threshold || @user.frequencies.count < @quantity_threshold
      return false
    end

    frequency = @user.frequencies.select{ |s| s.locality.eql?(locality) }.first
    percentage = BigDecimal(frequency.value) / BigDecimal(sum)

    percentage < @epsilon

  end
end