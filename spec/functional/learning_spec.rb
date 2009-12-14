require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neuronet do
	before do
		@it = Neuronet.new [2, 3, 1]
		@example = Example.new [0.2, 0.5], [0.6]
	end

	it "should learn example more exactly each time" do
		10.times do
			before = @it.result @example.input
			@it.learn @example
			((@it.result(@example.input)[0] - @example.output[0])**2 < (before[0] - @example.output[0])**2).should be_true
		end
	end

	it "should learn set of examples sample 1" do
		@it = Neuronet.new [2, 3, 1]
		@training_set = TrainingSet.build [0.3, 0.4] => [0.3]
		teach_net
	end

	it "should learn set of examples sample 2" do
		@it = Neuronet.new [2, 1]
		@training_set = TrainingSet.build [0.3, 0.4] => [0.3], [0.7, 0.2] => [0.7]
		teach_net
	end
#
#	it "should learn set of examples sample 3" do
#		@it = Neuronet.new [2, 1]
#		@training_set = {[0, 0] => [0], [0, 1] => [0], [1, 0] => [1], [1, 1] => [1]}
#		teach_net
#	end
#
#	it "should learn set of examples sample 4" do
#		@it = Neuronet.new [2, 1]
#		@training_set = {[0.3, 0.4] => [0.3], [0.7, 0.2] => [0.7], [0.21, 0.7] => [0.21]}
#		teach_net
#	end
#
#	it "should learn set of examples sample 5" do
#		@it = Neuronet.new [2, 1, 1]
#		@training_set = {[0.3, 0.4] => [0.3], [0.7, 0.2] => [0.7], [0.21, 0.7] => [0.21]}
#		teach_net
#	end

	protected

	def teach_net
		@it.teach_me(2000, @training_set)
		@training_set.each do |example|
			((@it.result(example.input)[0] - example.output[0])**2 < 0.1).should be_true, "for example: #{example.inspect}"
		end
	end
end