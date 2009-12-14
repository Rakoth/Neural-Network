require 'lib/main'

def func argument
	[Math.sin(argument).abs, Math.cos(argument).abs]
end

def fill_set values
	set = {}
	values.each do |coef|
		angle = coef * Math::PI
		set[[angle]] = func(angle)
		set[[-angle]] = func(-angle) unless 0 == angle
	end
	set
end

#test_set = fill_set Array.new(21) {|i| 0.05 * i}

#training_set_1 = fill_set Array.new(3) {|i| 0.5 * i}
#Report.new(Neuronet.new([1, 10, 10, 2]), 8000, training_set_1, test_set, 'f(x) = [|sin(x)|, |cos(x)|]').build!
#
#training_set_2 = fill_set Array.new(5) {|i| 0.25 * i}
#Report.new(Neuronet.new([1, 10, 10, 2]), 8000, training_set_2, test_set, 'f(x) = [|sin(x)|, |cos(x)|]').build!
#
#training_set_3 = fill_set Array.new(11) {|i| 0.1 * i}
#Report.new(Neuronet.new([1, 10, 10, 2]), 25000, training_set_3, test_set, 'f(x) = [|sin(x)|, |cos(x)|]').build!


set_a = [
	[0, 0, -4, 1, 1],
	[2, -5, -6, 2, 3],
	[-1, 1, -2, 2, 2],
	[1, 3, -3, 4, 3],
	[4, 5, -3, 5, 5],
	[2, 1, -4, 0, 4],
	[0, 2, 3, 4, -2],
	[3, -2, -6, 3, 5]
]

set_b = [
	[1, 2, 1, 3, 1],
	[5, 4, 5, 5, 1],
	[1, 3, 5, 3, 4],
	[3, 1, 2, 4, 4],
	[0, 1, -4, 0, -1],
	[1, 2, -6, 0, -3],
	[2, -3, 1, 4, -1],
	[2, -4, -2, 3, -3]
]


training_set = {}
(set_a + set_b).each do |point|
	training_set[point] = [set_a.include?(point) ? 1 : 0]
end
Report.new(Neuronet.new([5, 3, 1]), 5000, training_set).build!
