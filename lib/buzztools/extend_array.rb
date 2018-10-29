require 'csv'

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
		filter_include!(aValues,aArray.dup)
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
		filter_exclude!(aValues,aArray.dup)
	end

	def to_csv
		def as_hash(aItem)
			aItem = aItem.attributes if aItem.respond_to?(:attributes)
			return aItem if aItem.is_a?(Hash)
			nil
		end
		item1 = as_hash(first)
		raise "Must be an array of hashes" unless item1 && item1.is_a?(Hash)
		fields = item1.keys.map(&:to_s).sort
		if fields.delete('id')
			fields.unshift('id')
		end
    CSV.generate do |csv|
      csv << fields
      self.each do |i|
	      next unless i = as_hash(i)
        csv << i.values_at(*column_names)
      end
    end
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
