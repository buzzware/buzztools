Fixnum.class_eval do

	def to_b(aDefault=false)
		self==0 ? false : true
	end

	def to_range(aMin,aMax=nil,aDefault=nil)
		(!aMin || (self >= aMin)) && (!aMax || (self <= aMax)) ? self : aDefault
	end

	def to_ms # eg. for 1.minute.to_ms
		self*1000
	end
end
