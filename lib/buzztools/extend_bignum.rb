Bignum.class_eval do

	def to_b(aDefault=false)
		self==0 ? false : true
	end

	def to_ms # eg. for 1.minute.to_ms
		self*1000.0
	end

end

Float.class_eval do

	def to_b(aDefault=false)
		self==0 ? false : true
	end

	def to_ms # eg. for 1.minute.to_ms
		self*1000.0
	end

end
