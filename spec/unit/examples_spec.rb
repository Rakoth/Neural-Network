require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe Example do
	before {@it = Example.new([1, 2], [2])}

	it "should build new instance" do
		@it.should_not be_nil
	end

	it "should give access to input and output" do
		@it.input.should == [1, 2]
		@it.output.should == [2]
	end
end