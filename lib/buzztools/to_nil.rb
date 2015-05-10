Array.class_eval do
	def to_nil
		self.empty? ? nil : self
	end
end

Bignum.class_eval do
	def to_nil
		self==0 ? nil : self
	end
end

Float.class_eval do
	def to_nil
		(self==0 || !self.finite?) ? nil : self
	end
end

Fixnum.class_eval do
	def to_nil
		self==0 ? nil : self
	end
end

Hash.class_eval do
	def to_nil
		self.empty? ? nil : self
	end
end

TrueClass.class_eval do
	def to_nil
		self
	end
end

FalseClass.class_eval do
	def to_nil
		nil
	end
end

NilClass.class_eval do
	def to_nil
		nil
	end
end

Symbol.class_eval do
	def to_nil
		self
	end
end

String.class_eval do
	def to_nil(aPattern=nil)
		return nil if self.empty?
		if aPattern
			return nil if (aPattern.is_a? Regexp) && (self =~ aPattern)
			return nil if aPattern.to_s == self
		end
		self
	end
end

Time.class_eval do
	def to_nil
		self
	end
end
