require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Layer do
	before do
		@net = mock()
		@it = Layer.new(@net)
	end

	describe "creating" do
		it "should save neuronet info" do
			@it.neuronet.should == @net
		end

		it "should find self position" do
			@net.stub!(:layers).and_return([nil, false, 'sdf', @it, 1])
			@it.position.should == 3
		end
	end
end