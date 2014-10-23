Bignum.class_eval do

	def to_b(aDefault=false)
		self==0 ? false : true
	end

end

# Float.class_eval do
#
# end
