Bignum.class_eval do

	def to_nil
		self==0 ? nil : self
	end

	def to_b(aDefault=false)
		self==0 ? false : true
	end

end

Float.class_eval do

	def to_nil
		(self==0 || !self.finite?) ? nil : self
	end

end