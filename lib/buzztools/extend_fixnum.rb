Fixnum.class_eval do

	def to_b(aDefault=false)
		self==0 ? false : true
	end

	def to_range(aMin,aMax=nil,aDefault=nil)
		(!aMin || (self >= aMin)) && (!aMax || (self <= aMax)) ? self : aDefault
	end

end
