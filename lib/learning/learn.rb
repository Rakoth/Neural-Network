class Neuronet
	EPSILON = 0.001

	def learn example
		@input, @output = example.input, example.output
		return true if sum_error < EPSILON

		eval_deltas
		update_weights

		false
	end

	def teach_me times, examples, report = nil
		times.times do |i|
			@current_max_error = 0
			examples.each do |example|
				learn(example)
				report.save_error!(example, error) if report and report.save_time?(i+1)
				@current_max_error = [@current_max_error, sum_error].max
			end
			if report and report.save_time?(i+1)
				report.save_max_error!(@current_max_error)
				report.save_weights!(connections)
			end
			if learned?
				report.last_step = i + 1 if report
				break
			end
			shake! if paralysis?
		end
	end

	def learned?
		@current_max_error <= EPSILON
	end

	P_STEPS_COUNT = 50
	P_ERROR_DELTA = 0.01
	P_ERROR_TO_EPSILON_RATIO = 10
	
	def paralysis?
		@max_errors ||= []
		@max_errors << @current_max_error
		@max_errors.shift if P_STEPS_COUNT < @max_errors.size
		return (P_STEPS_COUNT == @max_errors.size and
			EPSILON * P_ERROR_TO_EPSILON_RATIO < @current_max_error and
			@max_errors.all?{|error| (error - @current_max_error).abs < P_ERROR_DELTA})
	end

	def shake!
		connections.each do |connect|
			connect.weight += shake_value
		end
	end

	def shake_value
		rand - 0.5
	end

	def connections
		layers.reverse.map(&:neurons).flatten.map(&:connections).flatten
	end

	def error
		@error = []
		result(@input).each_with_index{|value, index| @error << (value - @output[index])}
		@error
	end
	
	protected

	def sum_error
		error.map{|value| value**2}.sum / 2.0
	end
	
	def eval_deltas
		@deltas = [@error]
		layers.reverse_each do |layer|
			@deltas.unshift layer.neurons.map{|neuron| neuron.delta(@deltas.first)}
		end
	end

	def update_weights
		connections.each do |connect|
			delta_for_weight = @deltas[connect.to.layer.position][connect.to.position]
			connect.update_weight(delta_for_weight)
		end
	end
end

module Neuron
	class Normal < Base
		def delta next_layer_deltas
			sum = 0
			output_connections.each_with_index do |connect, index|
				sum += next_layer_deltas[index] * connect.weight
			end
			Activate.derivative(sum_signal) * sum
		end

		def output_connections
			layer.neuronet.connections.select{|connect| self == connect.from}
		end

		module Activate
			def self.derivative param
				Math.unipolar_derivative(param, COEF)
			end
		end
	end

	class Output < Normal
		def delta error
			error[position] * Activate.derivative(sum_signal)
		end
	end
end

class Connection
	def update_weight delta
		self.weight += direction(delta) * step
	end

	protected

	def direction delta
		- delta * input
	end

	def step
		0.05
	end
end

class Example
	attr_reader :input, :output

	def initialize input, output
		@input = input
		@output = output
	end
end

class TrainingSet
	include Enumerable
	
	def self.build hash_or_file_name
		case hash_or_file_name
		when Hash
			new hash_or_file_name
		when String, nil
			load hash_or_file_name
		else
			raise ArgumentError, "#{hash_or_file_name} not expected as argument"
		end
	end
	
	def self.load file_name = nil
		file_name ||= File.join(ROOT, 'lib', 'learning', 'examples.yml')
		set = new
		YAML.load_file(file_name).each do |key, value|
			input = key.split.map(&:to_f)
			output = value.is_a?(String) ? value.split.map(&:to_f) : [value.to_f]
			set << Example.new(input, output)
		end
		set
	end
	
	def initialize hash = nil
		@examples = []
		@pointer = -1
		hash.each{|input, output| self << Example.new(input, output)} unless hash.nil?
	end

	def size
		@examples.size
	end
	
	def << example
		@examples << example
	end

	def each &block
		@examples.each &block
	end

	def next
		@examples[(@pointer += 1) % size] unless @examples.empty?
	end

	def to_hash
		@hash ||= {}
		each { |example| hash[example.input] = example.output } if @hash.empty?
		@hash
	end

	def empty?
		@examples.empty?
	end

	def expected_values component
		sort_by {|example| example.input[0]}.map{|example| example.output[component]}
	end

	def actual_values net, component
		sort_by {|example| example.input[0]}.map{|example| net.result(example.input)[component]}
	end
end

class Report
	SAVE_STEPS = 250
	LABELS_NUMBER = 5
	
	def initialize net, steps_count, examples, controll_set = {}, function = ''
		@net, @steps_count, @function = net, steps_count, function
		@last_step = @steps_count
		@examples, @controll_set = TrainingSet.build(examples), TrainingSet.build(controll_set)
		
		@report_name ="report_#{Time.now.strftime('%H-%M-%S')}"
		@report_dir = File.join(ROOT, 'reports', @report_name)
		FileUtils.mkdir_p @report_dir
		
		@weights, @errors, @max_errors = {}, {}, []

		@steps_to_save = [1]
		SAVE_STEPS.times{|i| @steps_to_save << (i+1) * steps_count / SAVE_STEPS}
	end

	attr_reader :errors, :outputs, :steps_to_save, :max_errors, :weights

	def save_error! example, error
		errors[example] ||= []
		errors[example] << error
	end

	def save_weights! connections
		connections.each do |connect|
			@weights[connect] ||= []
			@weights[connect] << connect.weight
		end
	end

	attr_writer :last_step

	def save_max_error! error
		@max_errors << error
	end

	def save_time? teach_step
		@steps_to_save.include?(teach_step)
	end

	def build!
		@net.teach_me @steps_count, @examples, self
		save_neuronet
		text_report
		weights_report
		max_error_report
		componets_errors_report
		output_report
	end

	def save_neuronet
		File.open(File.join(@report_dir, 'neuronet_dump.yml'), 'w') do |dump_file|
			YAML.dump(@net, dump_file)
		end
	end

	def text_report
		File.open(File.join(@report_dir, 'report.txt'), 'w') do |report|
			report.write("Апроксимируемая функция: #{@function}\n") unless @function.empty?
			report.write("=" * 60 + "\n")
			report.write("Архитектура сети: #{@net.neurons_on_layers.inspect}\n")
			report.write("=" * 60 + "\n")
			report.write("Количество итераций: #{@last_step}\n")
			report.write("=" * 60 + "\n")
			report.write("Обучающее множество:\n")
			report.write("#{@examples.map(&:input).sort.map(&:inspect).join("\n")}\n")
			report.write("=" * 60 + "\n")
			report.write("Тестовое множество:\n")
			report.write("#{@controll_set.map(&:input).sort.map(&:inspect).join("\n")}\n")
			report.write("=" * 60 + "\n")
			report.write("Итоговые значения весов (W(layer_position)(neuron_position)(position) = value):\n")
			report.write(@net.connections.map(&:inspect).join)
		end
	end

	def steps_labels
		lables ||= {}
		if lables.empty?
			show_each = SAVE_STEPS / LABELS_NUMBER
			pointer = -1
			@steps_to_save.select{0 == (pointer += 1) % show_each}.each_with_index do |step, index|
				lables[index * show_each] = step.to_s
			end
		end
		lables
	end

	def weights_report
		weights.group_by{|connection, w| connection.to}.each do |neuron, connections|
			datas = {}
			connections.each do |pair|
				connection = pair[0]
				weights_history = pair[1]

				datas["Вес: #{connection.position}"] = weights_history.map{|w| w.to_f.round_to(4)}
			end
			new_gruff_picture(
				:title => "График весов #{neuron.position + 1} нейрона на #{neuron.layer.position + 1} уровне",
				:datas => datas,
				:file_name => "weights_for_neuron_#{neuron.layer.position + 1}_#{neuron.position + 1}.png"
			)
		end
	end

	def max_error_report
		new_gruff_picture :title => "График максимальной ошибки", :dot_radius => 1, :line_width => 2,
			:datas => {"error" => max_errors.map{|e| e.to_f.round_to(4)}},
			:file_name => "max_error.png"
	end

	def componets_errors_report
		@net.output_layer.neurons.count.times do |i|
			datas = {}
			errors.each do |example, errors_history|
				datas[example.input.map{|input| input.to_f.round_to(4)}.inspect] = errors_history.map{|array| array[i].to_f.round_to(4)}
			end
			new_gruff_picture :title => "График ошибок компоненты #{i + 1}",
				:datas => datas,
				:file_name => "errors_#{i+1}.png"
		end
	end

	def output_report
		#TODO
		return if 1 < @net.input_layer.neurons.count or @controll_set.empty?
		@net.output_layer.neurons.count.times do |i|
			new_gruff_picture :title => "Выход #{i+1} компоненты",
				:datas => {"Исходное значение" => @controll_set.expected_values(i),
					"Полученное значение" => @controll_set.actual_values(@net, i)},
				:lables => {},
				:file_name => "output_#{i+1}.png"
		end
	end

	protected

	def new_gruff_picture params = {}
		g = Gruff::Line.new
		g.margins = params[:margins] || 25
		g.dot_radius = params[:dot_radius] || 0
		g.line_width = params[:line_width] || 1
		g.title = params[:title]
		g.labels =  params[:lables] || steps_labels
		params[:datas].each do |legend, data|
			g.data legend, data
		end
		g.write(File.join(@report_dir, params[:file_name]))
		g
	end
end
