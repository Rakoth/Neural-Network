class Neuronet
	def result input
		raise ArgumentError unless input.size == neurons_on_layers[0]
		clear_cache!
		save_input! input
		output_layer.neurons.map(&:result)
	end

	protected
	
	def save_input! input
		input_layer.neurons.each_with_index do |neuron, index|
			neuron.input = input[index]
		end
	end

	def clear_cache!
		layers.map(&:neurons).flatten.each do |neuron|
			neuron.result = nil
			neuron.sum_signal = nil
		end
	end
end

module Neuron
	class Normal < Base
		attr_writer :result, :sum_signal
		
		def result
			@result ||= Activate.function(sum_signal)
		end

		def sum_signal
			@sum_signal ||= connections.map(&:weight_signal).sum
		end

		module Activate
			COEF = 1
			
			def self.function param
				Math.unipolar(param, COEF)
			end
		end
	end

	class Input < Base
		def result
			input
		end
	end
end

class Connection
	def weight_signal
		input * weight
	end

	protected

	def input
		from.nil? ? 1 : from.result
	end
end
