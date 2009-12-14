class Neuronet
	def initialize neurons_on_layers
		raise ArgumentError unless neurons_on_layers.is_a?(Array)
		@neurons_on_layers = neurons_on_layers
		build
	end

	attr_reader :input_layer, :neurons_on_layers, :output_layer

	def hidden_layers
		@hidden_layers ||= []
	end

	def previous_layer current_position
		0 == current_position ? input_layer : layers[current_position - 1]
	end

	def layers
		hidden_layers + [output_layer]
	end

	protected

	def build
		build_layers
		build_neurons
		build_connections
	end

	def build_layers
		@input_layer = Layer.new(self)
		
		(neurons_on_layers.size - 2).times do
			hidden_layers << Layer.new(self)
		end

		@output_layer = Layer.new(self)
	end

	def build_neurons
		neurons_on_layers.first.times do
			input_layer.neurons << Neuron::Input.new(input_layer)
		end
		
		hidden_layers.each_with_index do |layer, index|
			neurons_on_layers[index + 1].times do
				layer.neurons << Neuron::Normal.new(layer)
			end
		end

		neurons_on_layers.last.times do
			output_layer.neurons << Neuron::Output.new(output_layer)
		end
	end

	def build_connections
		layers.each_with_index do |layer, index|
			layer.neurons.each do |to_neuron|
				to_neuron.connections << Connection.new(nil, to_neuron)
				previous_layer(index).neurons.each do |from_neuron|
					to_neuron.connections << Connection.new(from_neuron, to_neuron)
				end
			end
		end
	end
end

class Layer
	attr_reader :neuronet
	
	def initialize neuronet
		@neuronet = neuronet
	end

	def neurons
		@neurons ||= []
	end

	def position
		@position ||= @neuronet.layers.index self
	end

	def previous
		neuronet.previous_layer position
	end
end

module Neuron
	class Base
		INPUT = 0
		NORMAL = 1

		attr_reader :layer

		def initialize layer
			@layer = layer
		end

		def position
			@position ||= @layer.neurons.index self
		end
	end

	class Normal < Base
		def connections
			@connections ||= []
		end
	end

	class Output < Normal
	end

	class Input < Base
		attr_accessor :input
	end
end

class Connection
	attr_reader :from, :to
	attr_accessor :weight
	
	def initialize from_neuron, to_neuron
		@from = from_neuron
		@to = to_neuron
		@weight = 0
	end

	def position
		@position ||= @to.connections.index self
	end
end
