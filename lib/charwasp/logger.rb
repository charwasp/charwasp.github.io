module CharWasP::Logger
	@logger = Logger.new $stdout
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

	@logger.level = ENV['CHARWASP_LOG_LEVEL']&.to_sym || :info
end
