require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Neuron do
	before do
		@layer = mock
		@it = Neuron::Normal.new(@layer)
		@input = Neuron::Input.new(@layer)
		@output = Neuron::Output.new(@layer)
	end

	describe "creating" do
		it "should save layer info" do
			[@it, @input, @output].each do |neuron|
				neuron.layer.should == @layer
			end
		end

		it "should find self position" do
			@layer.stub!(:neurons).and_return([@input, @it, @output])
			@input.position.should == 0
			@it.position.should == 1
			@output.position.should == 2
		end

		describe 'input' do
			before {@it = @input}

			it "should give accessor for input" do
				@it.should respond_to(:input)
				@it.should respond_to(:input=)
			end
		end
	end

	describe "replying" do
		describe "input" do
			before do
				@it = @input
			end

			it "should return input as result" do
				@it.input = 2
				@it.result.should == 2
			end
		end

		describe "normal" do
			before do
				@it.stub!(:connections).and_return([mock(:weight_signal => 1), mock(:weight_signal => 2)])
				Neuron::Normal::Activate.stub!(:function).and_return{|param| param * 2}
			end

			it "should eval result" do
				@it.result.should == 6
			end

			it "should eval sum signal" do
				@it.stub!(:connections).and_return([mock(:weight_signal => 1), mock(:weight_signal => 2)])
				@it.sum_signal.should == 3
			end
		end
	end

	describe "learning" do
		before do
			@layer = mock()
			@it = Neuron::Normal.new(@layer)
			@output = Neuron::Output.new(@layer)
			@layer.stub!(:neurons).and_return([mock, @it, @output])
			Neuron::Normal::Activate.stub!(:derivative).and_return(0.5)
		end

		it "should find output connections" do
			@layer.stub!(:neuronet => mock(
				:connections => [mock(:from => @it), mock(:from => nil), mock(:from => @it)]
			))
			@it.output_connections.should == [@layer.neuronet.connections[0], @layer.neuronet.connections[2]]
		end

		it "should eval output delta sample 1" do
			@output.stub!(:position).and_return(0)
			@output.delta([0.3]).should == 0.3 * 0.5
		end

		it "should eval hidel layer delta" do
			@it.stub!(:position).and_return(0)
			@it.stub!(:output_connections).and_return([mock(:weight => 0.4), mock(:weight => 0.1)])
			@it.delta([0.3, 0.2]).should == (0.3 * 0.4 + 0.2 * 0.1) * 0.5
		end
	end
end