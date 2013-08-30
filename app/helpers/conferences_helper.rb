module ConferencesHelper
	def conference_root(conference)
		subdomain = conference.subdomain
		domain = controller.request.domain
		protocol = controller.request.protocol
		port_string = controller.request.port_string
		"#{protocol}#{subdomain}.#{domain}#{port_string}"
	end
end
