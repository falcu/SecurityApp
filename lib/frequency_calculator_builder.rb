
class FrequencyCalculatorBuilder

  def get_calculator(user)
    calculator = LowFrequencyPercentage.new(user)
    calculator.set_quantity_threshold(6)
    calculator.set_sum_threshold(300)
    calculator.set_epsilon(0.01)
    calculator
  end

end