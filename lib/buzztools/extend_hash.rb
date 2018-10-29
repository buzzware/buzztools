module HashUtils

	public

	def filter_include!(aKeys,aHash=nil)
		aHash ||= self

		if aKeys.is_a? Regexp
			return aHash.delete_if {|k,v| not k =~ aKeys }
		else
			aKeys = [aKeys] unless aKeys.is_a? Array
			return aHash.clear if aKeys.empty?
			return aHash.delete_if {|key, value| !((aKeys.include?(key)) || (key.is_a?(Symbol) and aKeys.include?(key.to_s)) || (key.is_a?(String) and aKeys.include?(key.to_sym)))}
			return aHash	# last resort
		end
	end

	def filter_include(aKeys,aHash=nil)
		aHash ||= self
		filter_include!(aKeys,aHash.dup)
	end

	def filter_exclude!(aKeys,aHash=nil)
		aHash ||= self

		if aKeys.is_a? Regexp
			return aHash.delete_if {|k,v| k =~ aKeys }
		else
			aKeys = [aKeys] unless aKeys.is_a? Array
			return aHash if aKeys.empty?
			return aHash.delete_if {|key, value| ((aKeys.include?(key)) || (key.is_a?(Symbol) and aKeys.include?(key.to_s)) || (key.is_a?(String) and aKeys.include?(key.to_sym)))}
		end
	end

	def filter_exclude(aKeys,aHash=nil)
		aHash ||= self
		filter_exclude!(aKeys,aHash.dup)
	end

	def has_values_for?(aKeys,aHash=nil)
		aHash ||= self
		# check all keys exist in aHash and their values are not nil
		aKeys.all? { |k,v| aHash[k] }
	end

	# give a block to execute without the given key in this hash
	# It will be replaced after the block (guaranteed by ensure)
	# eg.
	# hash.without_key(:blah) do |aHash|
	#		puts aHash.inspect
	# end
	def without_key(aKey)
		temp = nil
		h = self
		begin
			if h.include?(aKey)
				temp = [aKey,h.delete(aKey)]
			end
			result = yield(h)
		ensure
			h[temp[0]] = temp[1] if temp
		end
		return result
	end

	def symbolize_keys
		result = {}
		self.each { |k,v| k.is_a?(String) ? result[k.to_sym] = v : result[k] = v  }
		return result
	end

	def compact
		self.reject {|k,v| v==nil}
	end

end

Hash.class_eval do
	include HashUtils
end

if defined? HashWithIndifferentAccess
	HashWithIndifferentAccess.class_eval do
		include HashUtils
	end
end
