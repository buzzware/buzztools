Time.class_eval do

	if !respond_to?(:change)  # no activesupport loaded
		def change(options)
			::Time.send(
				self.utc? ? :utc : :local,
				options[:year]  || self.year,
				options[:month] || self.month,
				options[:day]   || self.day,
				options[:hour]  || self.hour,
				options[:min]   || (options[:hour] ? 0 : self.min),
				options[:sec]   || ((options[:hour] || options[:min]) ? 0 : self.sec),
				options[:usec]  || ((options[:hour] || options[:min] || options[:sec]) ? 0 : self.usec)
			)
		end

		def seconds_since_midnight
			self.to_i - self.change(:hour => 0).to_i + (self.usec/1.0e+6)
		end

		def beginning_of_day
			(self - self.seconds_since_midnight).change(:usec => 0)
		end

		alias :midnight :beginning_of_day
		alias :at_midnight :beginning_of_day
		alias :at_beginning_of_day :beginning_of_day

	end

	# offset of local machine from UTC, in seconds eg +9.hours
	def self.local_offset
		local(2000).utc_offset
	end

	def date
		self.at_beginning_of_day
	end

	# index number of this day, from Time.at(0) + utc_offset
	def day_number
		(self.to_i+self.utc_offset) / 86400
	end

	# index number of this utc day
	def day_number_utc
		self.to_i / 86400
	end

	# the last microsecond of the day
	def day_end
		self.at_beginning_of_day + 86399.999999
	end

	def date_numeric
		self.strftime('%Y%m%d')
	end

	def to_universal
		self.strftime("%d %b %Y")
	end

	# create a new Time from eg. "20081231"
	def self.from_date_numeric(aString)
		return nil unless aString
		local(aString[0,4].to_i,aString[4,2].to_i,aString[6,2].to_i)
	end

	def time_numeric
		self.strftime('%H%M%S')
	end

	def datetime_numeric
		self.strftime('%Y%m%d-%H%M%S')
	end

	def to_sql_format # was to_sql, but clashed with Rails 3
		self.strftime('%Y-%m-%d %H:%M:%S')
	end

	def to_w3c
		utc.strftime("%Y-%m-%dT%H:%M:%S+00:00")
	end

	# returns an integer date stamp (milliseconds since 1970) compatible with Javascript
	def to_ms
		(to_f*1000).round
	end

	# creates a Time object from an integer date stamp (milliseconds since 1970) compatible with Javascript
	def self.from_ms(aMilliseconds)
		at(aMilliseconds/1000.0)
	end
end
