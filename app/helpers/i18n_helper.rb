module I18nHelper
	def t(*args)
		if args.last.kind_of? Hash
			args.last.merge(:namespace => current_conference.tag) unless args.last[:namespace]
		else
			if respond_to? :current_conference
				args.push({:namespace => current_conference.tag})
			else
				raise "Must specify :namespace in #t unless respond to #current_conference"
			end
		end
		translate(*args)
	end
end
