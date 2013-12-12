module ExtendArray

	module_function # this makes the methods accessible on the module as well as instances when the module is included into a class

	public

	def filter_include!(aValues,aArray=nil)
		aArray ||= self
		if aValues.is_a? Array
			return aArray if aValues.empty?
			return aArray.delete_if {|v| not aValues.include? v }
		elsif aValues.is_a? Regexp
			return aArray.delete_if {|v| not v =~ aValues }
		else
			return filter_include!([aValues],aArray)
		end
	end

	def filter_include(aValues,aArray=nil)
		aArray ||= self
		filter_include!(aValues,aArray.clone)
	end

	def filter_exclude!(aValues,aArray=nil)
		aArray ||= self
		if aValues.is_a? Array
			return aArray if aValues.empty?
			return aArray.delete_if {|v| aValues.include? v }
		elsif aValues.is_a? Regexp
			return aArray.delete_if {|v| v =~ aValues }
		else
			return filter_exclude!([aValues],aArray)
		end
	end

	def filter_exclude(aValues,aArray=nil)
		aArray ||= self
		filter_exclude!(aValues,aArray.clone)
	end

	def to_nil
		self.empty? ? nil : self
	end
end

Array.class_eval do
	include ExtendArray
	# fixes a memory leak in shift in Ruby 1.8 - should be fixed in 1.9
	# see http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-talk/216055
	#def shift()
	#	delete_at(0)
	#end
end
