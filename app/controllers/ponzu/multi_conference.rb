module Ponzu
	module MultiConference
		def self.included(base)
			base.helper_method :conference_module, :conference_tag, 
				                 :current_conference, :conference_name
			base.before_filter :redirect_unless_conference_found
    end

		private

		def current_conference
			@current_conference ||= Conference.find_by_subdomain(request.subdomain)
		end

		def conference_module
			current_conference.module_name
		end

		def conference_name
			current_conference.name
		end

		def conference_tag
			current_conference.tag
		end

		def conference_subdomain
			current_conference.subdomain
		end

		def redirect_unless_conference_found
			redirect_to "/#{request.subdomain}/index.html" unless current_conference
			return false
		end

	end
end