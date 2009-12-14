module Math
	def self.unipolar argument, coefficient
		u, a = argument, coefficient
		1 / (1 + exp(-a * u))
	end

	def self.unipolar_derivative argument, coefficient
		temp = unipolar(argument, coefficient)
		temp * (1 - temp)
	end
end

class Array
	def sum
		inject(0){|sum, val| sum += val}
	end
end

class Float
  def round_to(x)
		multiply = 10**x
    (self * multiply).round.to_f / multiply
  end
end