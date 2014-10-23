NilClass.class_eval do

	def to_b(aDefault=false)
		false
	end

	def g?(*args)
		nil
	end

end

TrueClass.class_eval do

	def to_b(aDefault=false)
		self
	end

end

FalseClass.class_eval do

	def to_b(aDefault=false)
		self
	end

end


Math.module_eval do
	def self.max(a, b)
		a > b ? a : b
	end

	def self.min(a, b)
		a < b ? a : b
	end
end
