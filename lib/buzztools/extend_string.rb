String.class_eval do

	def self.random_word(min=4,max=8)
		len = min + rand(max-min+1)
		result = ' '*len
		(len-1).downto(0) {|i| result[i] = (?a.ord + rand(?z.ord-?a.ord+1)).chr}
		return result
	end

	def pad_left(value)
		increase = value-self.length
		return self if increase==0
		if increase > 0
			return self + ' '*increase
		else
			return self[0,value]
		end
	end

	def pad_right(value)
		increase = value-self.length
		return self if increase==0
		if increase > 0
			return ' '*increase + self
		else
			return self[0,value]
		end
	end

	# Like bite, but returns the first match instead of the subject, and removes the match from the subject, modifying it
	def extract!(aValue=$/,aString=self)
		if aValue.is_a? String
			if i = aString.index(aValue)
				aString[i,aValue.length] = ''
				return aValue
			else
				return nil
			end
		elsif aValue.is_a? Regexp
			if md = aValue.match(aString)
				aString[md.begin(0),md.end(0)-md.begin(0)] = ''
				return md.to_s
			else
				return nil
			end
		else
			return aString
		end
	end

	def extract(aValue=$/)
		extract!(aValue,self.clone)
	end

	# Like chomp! but operates on the leading characters instead.
	# The aString parameter would not normally be used.
	def bite!(aValue=$/,aString=self)
		if aValue.is_a? String
			if aString[0,aValue.length] == aValue
				aString[0,aValue.length] = ''
				return aString
			else
				return aString
			end
		elsif aValue.is_a? Regexp
			return aString.sub!(aValue,'') if aString.index(aValue)==0
		else
			return aString
		end
	end

	def bite(aValue=$/)
		bite!(aValue,self.clone)
	end

	def deprefix!(aPrefix=$/,aString=self)
		if aString[0,aPrefix.length] == aPrefix
			aString[0,aPrefix.length] = ''
			return aString
		else
			return aString
		end
	end

	def deprefix(aValue=$/)
		deprefix!(aValue,self.clone)
	end

	def desuffix!(aString,aSuffix)
		if aString[-aSuffix.length,aSuffix.length] == aSuffix
			aString[-aSuffix.length,aSuffix.length] = ''
			return aString
		else
			return aString
		end
	end

	def desuffix(aValue=$/)
		desuffix!(aValue,self.clone)
	end

	def begins_with?(aString)
		self[0,aString.length]==aString
	end

	def ends_with?(aString)
		self[-aString.length,aString.length]==aString
	end

	def ensure_prefix!(aPrefix=$/,aString=self)
		aString[0,0]=aPrefix unless aString.begins_with?(aPrefix)
		aString
	end

	def ensure_prefix(aValue=$/)
		ensure_prefix!(aValue,self.clone)
	end

	def ensure_suffix!(aSuffix=$/,aString=self)
		aString.insert(-1,aSuffix) unless aString.ends_with?(aSuffix)
		aString
	end

	def ensure_suffix(aValue=$/)
		ensure_suffix!(aValue,self.clone)
	end

	def to_integer(aDefault=nil)
		t = self.strip
		return aDefault if t.empty? || !t.index(/^-{0,1}[0-9]+$/)
		return t.to_i
	end

	def is_i?
		self.to_integer(false) and true
	end

	def to_float(aDefault=nil)
		t = self.strip
		return aDefault if !t =~ /(\+|-)?([0-9]+\.?[0-9]*|\.[0-9]+)([eE](\+|-)?[0-9]+)?/
		return t.to_f
	end

	def is_f?
		self.to_float(false) and true
	end

	# like scan but returns array of MatchData's.
	# doesn't yet support blocks
	def scan_md(aPattern)
		result = []
		self.scan(aPattern) {|s| result << $~ }
		result
	end

	def to_nil(aPattern=nil)
		return nil if self.empty?
		if aPattern
			return nil if (aPattern.is_a? Regexp) && (self =~ aPattern)
			return nil if aPattern.to_s == self
		end
		self
	end

	def to_b(aDefault=false)
		return true if ['1','yes','y','true','on'].include?(self.downcase)
		return false if ['0','no','n','false','off'].include?(self.downcase)
		aDefault
	end

	# "...Only alphanumerics [0-9a-zA-Z], the special characters "$-_.+!*'()," [not including the quotes - ed], and reserved characters used for their reserved purposes may be used unencoded within a URL."

	URLIZE_SEPARATORS = /[ \\\(\)\[\]\.*,]/	# was /[ \\\(\)\[\]\.*,]/
	URLIZE_EXTENSIONS = %w(html htm jpg jpeg png gif bmp mov avi mp3 zip pdf css js doc xdoc)
	URLIZE_REMOVE = /[^a-z0-9\_\-+~\/]/ # was 'a-z0-9_-+~/'
	# aKeepExtensions may be an array of extensions to keep, or :none (will remove periods) or :all (any extension <= 4 chars)
	def urlize(aSlashChar='+',aRemove=nil,aKeepExtensions=nil)
		aKeepExtensions=URLIZE_EXTENSIONS if !aKeepExtensions
		aRemove=URLIZE_REMOVE if !aRemove
		return self if self.empty?
		result = self.downcase
		ext = nil
		if (aKeepExtensions!=:none) && last_dot = result.rindex('.')
			if (ext_len = result.length-last_dot-1) <= 4	# preserve extension without dot if <= 4 chars long
				ext = result[last_dot+1..-1]
				ext = nil unless aKeepExtensions==:all || (aKeepExtensions.is_a?(Array) && aKeepExtensions.include?(ext))
				result = result[0,last_dot] if ext
			end
		end

		result = result.gsub(URLIZE_SEPARATORS,'-')
		result = result.gsub(aRemove,'').sub(/-+$/,'').sub(/^-+/,'')
		result.gsub!('/',aSlashChar) unless aSlashChar=='/'
		result.gsub!(/-{2,}/,'-')
		result += '.'+ext if ext
		result
	end

	def has_tags?
		index(/<[a-zA-Z\-:0-9]+(\b|>)/) && (index('/>') || index('</'))		# contains an opening and closing tag
	end

	def snake_case
		underscore.tr(' ','_')
	end

	def relative_url?
		!begins_with?('http') || !begins_with?('/')
	end

	def to_file(aFilename)
		File.open(aFilename,'wb') {|file| file.write self }
	end

	def self.from_file(aFilename)
		File.open(aFilename, "rb") { |f| f.read }
	end
end


Symbol.class_eval do
	def to_nil
		self
	end
end
