require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe TrainingSet do
	before {@it = TrainingSet.new}

	it "should be empty" do
		@it.size.should == 0
	end

	it "should add an examples to self collection" do
		example = Example.new([1, 2], [2])
		@it << example
		@it.size.should == 1
	end

	it "should load examples from file" do
		@it = TrainingSet.build(File.join(File.dirname(__FILE__), '..', 'files', 'test_examples.yml'))
		@it.size.should == 3
	end

	it "should bu stuff for each example in collection" do
		@it = TrainingSet.build(File.join(File.dirname(__FILE__), '..', 'files', 'test_examples.yml'))
		outputs = []
		@it.each do |example|
			outputs << example.output
		end
		outputs.sort.should == [[0], [1], [1]].sort
	end

	it "should give next example" do
		examples = {[0,4] => [1], [0,3] => [3]}
		@it = TrainingSet.build(examples)
		@it.next.should be_an_instance_of(Example)
		examples.values.should include(@it.next.output)
	end
end