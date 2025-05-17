module CharWasP::Logger
	singleton_class.attr_reader :logger

	def self.level
		@logger.level
	end

	def self.level= level
		@logger.level = level
	end

	%i[debug info warn error fatal unknown].each do |level|
		define_method level do |message|
			CharWasP::Logger.logger.send level, message
		end
		module_function level
	end

	begin
		require 'logger'
		@logger = Logger.new $stdout
	rescue LoadError
		class << @logger = Object.new
			attr_accessor :level
			%i[debug info warn error fatal unknown].each do |level|
				define_method(level) { puts _1 }
			end
		end
	ensure
		@logger.level = ENV['CHARWASP_LOG_LEVEL']&.to_sym || :info
	end
end
