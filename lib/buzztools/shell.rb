module Buzztools
	module Shell
		module_function

		# from whenever crontab
		#/bin/bash -l -c 'cd /var/www/homeopen.com/releases/20140714092436 && bin/rails runner -e production '\''scripts/update_contacts.rb'\'' >> log/cron.log 2>&1'

		def run(aCommand)
			`/bin/bash -l -c 'cd "#{Rails.root.to_s}" && #{aCommand} 2>&1'`   			# bin/rails runner -e production '\''scripts/update_contacts.rb'\'' >> log/cron.log 2>&1'`
		end

		def runner(aScript,*args)
			pars = (args || []).join(' ')
			cmd = "rails runner -e #{Rails.env} #{aScript}"
			cmd += ' ' + pars if pars
			run(cmd)
		end
	end
end