module Buzztools
	module File

		module_function

		public

		def sniff_seperator(aPath)
			result = 0.upto(aPath.length-1) do |i|
				char = aPath[i,1]
				break char if char=='\\' || char=='/'
			end
			result = File::SEPARATOR if result==0
			return result
		end

		def append_slash(aPath,aSep=nil)
			aSep = sniff_seperator(aPath) unless aSep
			aPath.ensure_suffix(aSep)
		end

		def remove_slash(aPath)
			last_char = aPath[-1,1]
			aPath = aPath[0..-2] if last_char=='\\' || last_char=='/'
			return aPath
		end

		#def ensure_prefix(aString,aPrefix)
		#	aString.begins_with?(aPrefix) ? aString : aPrefix+aString
		#end
		#
		#def ensure_suffix(aString,aSuffix)
		#	aString.ends_with?(aSuffix) ? aString : aString+aSuffix
		#end

		# Remove base dir from given path. Result will be relative to base dir and not have a leading or trailing slash
		#'/a/b/c','/a' = 'b/c'
		#'/a/b/c','/' = 'a/b/c'
		#'/','/' = ''
		def path_debase(aPath,aBase)
			aBase = append_slash(aBase)
			aPath = remove_slash(aPath) unless aPath=='/'
			aPath[0,aBase.length]==aBase ? aPath[aBase.length,aPath.length-aBase.length] : aPath
		end

		def path_rebase(aPath,aOldBase,aNewBase)
			rel_path = path_debase(aPath,aOldBase)
			append_slash(aNewBase)+rel_path
		end

		def path_combine(aBasePath,aPath)
			return aBasePath if !aPath
			return aPath if !aBasePath
			return path_relative?(aPath) ? File.join(aBasePath,aPath) : aPath
		end

		# make path real according to file system
		def real_path(aPath)
			(path = Pathname.new(File.expand_path(aPath))) && path.realpath.to_s
		end

		# takes a path and combines it with a root path (which defaults to Dir.pwd) unless it is absolute
		# the final result is then expanded
		def canonize_path(aPath,aRootPath=nil)
			path = path_combine(aRootPath,aPath)
			path = real_path(path) if path
			path
		end

		def find_upwards(aStartPath,aPath)
			curr_path = File.expand_path(aStartPath)
			while curr_path && !(test_path_exists = File.exists?(test_path = File.join(curr_path,aPath))) do
				curr_path = path_parent(curr_path)
			end
			curr_path && test_path_exists ? test_path : nil
		end

		# allows special symbols in path
		# currently only ... supported, which looks upward in the filesystem for the following relative path from the basepath
		def expand_magic_path(aPath,aBasePath=nil)
			aBasePath ||= Dir.pwd
			path = aPath
			if path.begins_with?('...')
				rel_part = path.split3(/\.\.\.[\/\\]/)[2]
				path = find_upwards(aBasePath,rel_part)
			end
		end

		def path_parent(aPath)
			return nil if is_root_path?(aPath)
			append_slash(File.dirname(remove_slash(expand_path(aPath))))
		end

		def simple_dir_name(aPath)
			File.basename(remove_slash(aPath))
		end

		def simple_file_name(aPath)
			f = File.basename(aPath)
			dot = f.index('.')
			return dot ? f[0,dot] : f
		end

		def path_parts(aPath)
			sep = sniff_seperator(aPath)
			aPath.split(sep)
		end
	end
end