module Buzztools

	lgr = (defined? ActiveSupport::BufferedLogger) ? ActiveSupport::BufferedLogger : Logger


	# The default level is DEBUG to pass all output to the sub-loggers, but the sub-loggers level will also determine what is output to their destinations
	class MultiLogger < Logger

		attr_reader :loggers
		# if !self.instance_methods.include?(:formatter)
		# 	def formatter
		# 		@formatter ||= Logger::Formatter.new
		# 	end
		# 	attr_writer :formatter
		# end

		def initialize(aLoggers)
			super(nil)
			@level = Severity::DEBUG
			@loggers = aLoggers.is_a?(Array) ? aLoggers : [aLoggers]
		end

		def add(severity, message = nil, progname = nil, &block)
			return true if !@loggers
			severity ||= UNKNOWN
			@loggers.each do |lr|
				block_given? ? lr.add(severity, message, progname, &block) : lr.add(severity, message, progname)
			end
			true
		end

		alias log add

		def <<(msg)
			@loggers.each do |lr|
				lr << msg
			end
		end

		def close
			@loggers.each do |lr|
				lr.close
			end
		end

	end

	#DEBUG D
	#INFO
	#WARN ?
	#ERROR !
	#FATAL F
	#UNKNOWN U

	# Logger that mostly works like a STDOUT logger, except that warnings and above get sent to STDERR instead

	class ConsoleLogger < lgr

		class ReportFormatter < Logger::Formatter
			def call(severity, time, progname, msg)
				msg2str(msg)+"\n"
			end
		end

		def initialize(aErrLevel = Severity::WARN)
			super(STDOUT)
			self.formatter = ReportFormatter.new
			self.level = Severity::INFO
			self << "\n"
			@err_logger = Logger.new(STDERR)
			@err_level = aErrLevel
			@err_logger.formatter = ReportFormatter.new
		end

		if !self.instance_methods.include?(:formatter)
			def formatter
				@formatter ||= Logger::Formatter.new
			end
			attr_writer :formatter
		end

		alias_method :orig_add, :add

		def add(severity, message = nil, progname = nil, &block)
			if severity >= @err_level
				block_given? ? @err_logger.add(severity, message, progname, &block) : @err_logger.add(severity, message, progname)
			else
				block_given? ? orig_add(severity, message, progname, &block) : orig_add(severity, message, progname)
			end
		end

		alias log add

		def <<(msg)
			dev = if self.class.superclass==ActiveSupport::BufferedLogger
				@log_dest
			else
				@logdev
			end
	    unless dev.nil?
	      dev.write(msg)
	    end
	  end


		def close
			begin
				@logdev.close if @logdev
			ensure
				@err_logger.close
			end
		end

	end


end