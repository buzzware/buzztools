# this pattern of declaring methods in a module and then including into a class means that the methods can be used directly from the module
#   eg. ExtendObject::attr_from_json(json,object)
# or on the class it is included into
#   eg. model.attr_from_json(json)
module ExtendObject

	module_function # this makes the methods accessible on the module as well as instances when the module is included into a class

	public

	def attr_from_json(aJsonObject,aObject=nil)   # only give second argument when used like ExtendObject::attr_from_json
		aObject ||= self
		rubyObj = JSON.parse!(aJsonObject)
		rubyObj.each do |k,v|
			aObject.send k.to_sym,v
		end
		aObject
	end

	def g?(*args)
		if args.length==1
			path = args.first
		else
			path = args
		end
		if path.is_a?(String)
			segments = path.split('.')
			segment = segments.shift
		elsif path.is_a?(Symbol)
			path = path.to_s
			segments = [path]
			segment = segments.shift
		elsif path.is_a?(Array)
			segments = path
			segment = segments.shift
			#segment = segment.to_sym if segment
		end
		return self unless segment.to_nil
		value = if self.is_a?(Array)
			self[segment.to_i] rescue nil
		elsif (self.respond_to?(segment.to_sym) rescue nil)
			self.send(segment)
		elsif self.respond_to?(:[])
			(begin self[segment] rescue nil end) || (begin self[segment.to_sym] rescue nil end)
		end
		if segments.empty?
			value
		else
			value.respond_to?(:g?) ? value.g?(segments) : nil
		end
	end

end

Object.class_eval do
	include ExtendObject
end
