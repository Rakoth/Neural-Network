require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Connection do
	before do
		@from_neuron = mock
		@to_neuron = mock
		@it = Connection.new(@from_neuron, @to_neuron)
	end

	describe "creating" do
		it "should save neurons info" do
			@it.from.should == @from_neuron
			@it.to.should == @to_neuron
		end

		it "should set default value for weigth" do
			@it.weight.should == 0
		end

		it "should find self position" do
			@to_neuron.stub!(:connections).and_return(mock(:index => 2))
			@it.position.should == 2
		end
	end

	describe "replying" do
		describe "neurons connection" do
			before do
				@from_neuron.stub!(:result).and_return(2)
			end

			it "should eval weights signal" do
				@it.weight_signal.should_not be_nil
			end

			it "should eval weights signal if weight changed" do
				@it.weight = 4
				@it.weight_signal.should == 8
			end
		end

		describe "polarization" do
			before do
				@it.stub!(:from).and_return(nil)
			end

			it "should return own weight" do
				@it.weight_signal.should_not be_nil
			end

			it "should return own weight if weight changed" do
				@it.weight = 3.5
				@it.weight_signal.should == 3.5
			end
		end
	end

	describe "learning" do
		it "should update weight" do
			@it.stub!(:input => 0.4, :step => 1.0)
			@it.weight = 0.1
			@it.update_weight(0.5)
			@it.weight.should == 0.1 - 0.4 * 0.5 * 1.0
		end
	end
end