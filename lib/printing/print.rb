class Neuronet
	def inspect
		"Neuronet:\n\tneurons_on_layers: #{neurons_on_layers * ", "}\n\n#{input_layer.inspect}\n\n#{layers.map(&:inspect)}"
	end
end

class Layer
	def inspect
		"#{nil == position ? "Input" : "Normal##{position}"} Layer:\n\tneurons:\n#{neurons.map(&:inspect)}"
	end
end

module Neuron
	class Normal < Base
		def inspect
			"\tNeuron #{position}: \n#{connections.map(&:inspect)}"
		end
	end

	class Input < Base
		def inspect
			"\t<InputNeuron##{position}, input: #{input}>\n"
		end
	end
end

class Connection
	def inspect
		"W(#{to.layer.position})(#{to.position})(#{position}) = #{weight}\n"
	end
end
