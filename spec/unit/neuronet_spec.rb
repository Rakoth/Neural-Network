require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neuronet do
	describe "creating" do
		before do
			@neurons_on_layers = [1,2,1,4,2]
			@it = Neuronet.new(@neurons_on_layers)
		end

		it "should save neurons count info" do
			@it.neurons_on_layers.should == @neurons_on_layers
		end

		it "should build correct count of layers" do
			@it.input_layer.should_not be_nil
			@it.hidden_layers.size.should == @neurons_on_layers.size - 2
			@it.output_layer.should_not be_nil
		end

		it "should build own layers" do
			@it.input_layer.neuronet.should == @it
			@it.hidden_layers.each do |layer|
				layer.neuronet.should == @it
			end
			@it.output_layer.neuronet.should == @it
		end

		it "should build correct count of neurons" do
			@it.input_layer.neurons.size.should == @neurons_on_layers[0]
			@it.layers.map{|layer| layer.neurons.size}.each_with_index do |count, index|
				count.should == @neurons_on_layers[index + 1]
			end
		end
		
		it "should build neurons of correct type" do
			@it.input_layer.neurons.all?{|neuron| neuron.instance_of?(Neuron::Input)}.should be_true
			@it.hidden_layers.map(&:neurons).each do |neurons|
				neurons.all?{|neuron| neuron.instance_of?(Neuron::Normal)}.should be_true
			end
			@it.output_layer.neurons.all?{|neuron| neuron.instance_of?(Neuron::Output)}.should be_true
		end

		it "should build self`s neurons" do
			([@it.input_layer] + @it.layers).each do |layer|
				layer.neurons.all?{|neuron| neuron.layer == layer}.should be_true
			end
		end

		it "should build correct count of connections" do
			@it.layers.each do |layer|
				layer.neurons.each do |neuron|
					neuron.connections.size.should == layer.previous.neurons.size + 1
				end
			end
		end

		it "should build self`s connections" do
			@it.layers.each do |layer|
				layer.neurons.each do |neuron|
					neuron.connections.all?{|connection| connection.to == neuron}.should be_true
				end
			end
		end
	end

	describe "replying" do
		describe "layers managing" do
			before do
				@neurons_on_layers = [1, 2, 1]
				@it = Neuronet.new @neurons_on_layers
			end

			it "should find previous layer" do
				@it.layers.first.previous.should == @it.input_layer
				@it.layers.last.previous.should == @it.layers.first
			end

			it "should find layers" do
				@it.layers.should == @it.hidden_layers + [@it.output_layer]
			end
		end

		describe "eval result" do
			describe 'sample 1' do
				before do
					@neurons_on_layers = [1, 2]
					@it = Neuronet.new @neurons_on_layers
					@input = 2.4
				end

				it "should eval result for given input" do
					@it.result([@input]).should == [
						Neuron::Normal::Activate.function(0),
						Neuron::Normal::Activate.function(0)
					]
				end

				it "should eval result if weights are changed" do
					@it.output_layer.neurons[0].connections.first.weight = 1
					@it.output_layer.neurons[0].connections.last.weight = 1
					@it.output_layer.neurons[1].connections.first.weight = 0
					@it.output_layer.neurons[1].connections.last.weight = 2
					@it.result([@input]).should == [
						Neuron::Normal::Activate.function(@input + 1),
						Neuron::Normal::Activate.function(@input * 2)
					]
				end
			end

			describe "sample 2" do
				before do
					@neurons_on_layers = [3, 2, 1]
					@it = Neuronet.new @neurons_on_layers
					@i = [2.4, 3.1, 0.4]
				end

				it "should eval result for given input" do
					@it.result(@i).should == [Neuron::Normal::Activate.function(0)]
				end

				it "should eval result if weights are changed" do
					@it.layers[0].neurons[0].connections[0].weight = 0
					@it.layers[0].neurons[0].connections[1].weight = 1
					@it.layers[0].neurons[0].connections[2].weight = 2
					@it.layers[0].neurons[0].connections[3].weight = 1

					@it.layers[0].neurons[1].connections[0].weight = 1
					@it.layers[0].neurons[1].connections[1].weight = 1
					@it.layers[0].neurons[1].connections[2].weight = 2
					@it.layers[0].neurons[1].connections[3].weight = 3

					@it.layers[1].neurons[0].connections[0].weight = 2
					@it.layers[1].neurons[0].connections[1].weight = 1
					@it.layers[1].neurons[0].connections[2].weight = 2

					@it.result(@i).should == [Neuron::Normal::Activate.function(
							2 +
								Neuron::Normal::Activate.function(@i[0] + 2 * @i[1] + @i[2]) +
								2 * Neuron::Normal::Activate.function(1 + @i[0] + 2 * @i[1] + 3 * @i[2])
						)]
				end
			end

			describe "cache result in neurons" do
				before do
					@it = Neuronet.new [1,2]
					@it.result [1]
				end

				it "should cache result in neurons" do
					@it.output_layer.neurons.each do |neuron|
						neuron.instance_variable_get(:@result).should == Neuron::Normal::Activate.function(0)
					end
				end

				it "should cache result in neurons" do
					@it.send(:clear_cache!)
					@it.output_layer.neurons.each do |neuron|
						neuron.instance_variable_get(:@result).should be_nil
						neuron.instance_variable_get(:@sum_signal).should be_nil
					end
				end
			end
		end
	end

	describe "learning" do
		describe "connections" do
			before do
				@it = Neuronet.new [1, 1, 1]
				@connections = [
					@it.output_layer.neurons[0].connections[0],
					@it.output_layer.neurons[0].connections[1],
					@it.hidden_layers[0].neurons[0].connections[0],
					@it.hidden_layers[0].neurons[0].connections[1],
				]
			end

			it "should return connections in correct order" do
				@it.connections.should == @connections
			end
		end

		describe "paralysis" do
			before {@it = Neuronet.new [2,4]}
			
			it "should know about paralysis" do
				@it.instance_variable_set(:@max_errors, [1] * Neuronet::P_STEPS_COUNT)
				@it.instance_variable_set(:@current_max_error, 1)
				@it.paralysis?.should be_true
			end

			it "should wait some steps to be shure" do
				@it.instance_variable_set(:@max_errors, [1] * (Neuronet::P_STEPS_COUNT - 2))
				@it.instance_variable_set(:@current_max_error, 1)
				@it.paralysis?.should be_false
			end

			it "should not signalize paralysis if errors are changed" do
				@it.instance_variable_set(:@max_errors, [1] * Neuronet::P_STEPS_COUNT)
				@it.instance_variable_set(:@current_max_error, 2)
				@it.paralysis?.should be_false
			end

			it "should return shake value" do
				value = @it.shake_value
				(-1 < value and value < 1).should be_true
			end

			it "should shake weights for each neuron" do
				weights = @it.connections.map(&:weight)
				@it.shake!
				weights.should_not == @it.connections.map(&:weight)
			end
		end

		describe "sum_error method" do
			before {@it = Neuronet.new [1,1,1]}
			it "should eval error sample 1" do
				@it.instance_variable_set(:@output, [0.4])
				@it.stub!(:result).and_return([0.1])
				@it.send(:sum_error).to_f.should == ((0.4-0.1)**2)/2
			end

			it "should eval error sample 2" do
				@it.instance_variable_set(:@output, [0.4, 0.6])
				@it.stub!(:result).and_return([0.1, 0.7])
				@it.send(:sum_error).to_f.should == ((0.4-0.1)**2 + (0.7-0.6)**2)/2
			end

			it "should eval error sample 3" do
				@it.instance_variable_set(:@output, [1])
				@it.stub!(:result).and_return([0])
				@it.send(:sum_error).to_f.should == 0.5
			end
		end
	end
end