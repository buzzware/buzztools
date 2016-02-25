Time.class_eval do

	if !method_defined?(:change)  # no activesupport loaded
		def change(options)
			# ::Time.send(
			# 	self.utc? ? :utc : :local,
			# 	options[:year]  || self.year,
			# 	options[:month] || self.month,
			# 	options[:day]   || self.day,
			# 	options[:hour]  || self.hour,
			# 	options[:min]   || (options[:hour] ? 0 : self.min),
			# 	options[:sec]   || ((options[:hour] || options[:min]) ? 0 : self.sec),
			# 	options[:usec]  || ((options[:hour] || options[:min] || options[:sec]) ? 0 : self.usec)
			# )

			new_year  = options.fetch(:year, year)
	    new_month = options.fetch(:month, month)
	    new_day   = options.fetch(:day, day)
	    new_hour  = options.fetch(:hour, hour)
	    new_min   = options.fetch(:min, options[:hour] ? 0 : min)
	    new_sec   = options.fetch(:sec, (options[:hour] || options[:min]) ? 0 : sec)

	    if new_nsec = options[:nsec]
	      raise ArgumentError, "Can't change both :nsec and :usec at the same time: #{options.inspect}" if options[:usec]
	      new_usec = Rational(new_nsec, 1000)
	    else
	      new_usec  = options.fetch(:usec, (options[:hour] || options[:min] || options[:sec]) ? 0 : Rational(nsec, 1000))
	    end

	    if utc?
	      ::Time.utc(new_year, new_month, new_day, new_hour, new_min, new_sec, new_usec)
	    elsif zone
	      ::Time.local(new_year, new_month, new_day, new_hour, new_min, new_sec, new_usec)
	    else
	      raise ArgumentError, 'argument out of range' if new_usec > 999999
	      ::Time.new(new_year, new_month, new_day, new_hour, new_min, new_sec + (new_usec.to_r / 1000000), utc_offset)
	    end

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
	# It will be in local timezone
	def self.from_ms(aMilliseconds)
		at(aMilliseconds/1000.0)
	end

	def iso8601ms
		iso8601(3)
	end

	# "zoneless time" is a way of representing a time and date eg. 1am 1/1/1970 regardless of timezone.
	# This is done by converting it to the same time and date, but with the utc flag set
	# This means that Time.new(1970,1,1).zoneless.to_i will return the same value on any machine
	def zoneless
		(self + self.utc_offset).utc
	end

	# This sets the zone without affecting the hour or day
	# Useful for building a time object eg. New Year in Sydney : Time.new(2016,1,1).to_zone(10)
	def to_zone(aHours=nil)
		aHours ||= utc_offset/3600.0
		self.in_time_zone(aHours)+self.utc_offset-aHours.to_i.hours
	end

	# Useful for building a UTC/zoneless Time from ms since the epoch
	# For Freewheeler :
	# eg. Time.from_zoneless_ms(packet.timems).to_zone(packet.tzm/60)
	def self.from_zoneless_ms(aTimems)
		from_ms(aTimems).utc
	end
end

if defined? ActiveSupport::TimeWithZone
	ActiveSupport::TimeWithZone.class_eval do
		# see above
		def zoneless
			(self + self.utc_offset).utc
		end

		# see above
		# sets the zone without affecting the hour or day
		def to_zone(aHours=nil)
			aHours ||= utc_offset/3600.0
			self.in_time_zone(aHours)+self.utc_offset-aHours.to_i.hours
		end
	end
end