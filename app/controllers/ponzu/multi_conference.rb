module Ponzu
	module MultiConference
		def self.included(base)
			base.helper_method :conference_module, :conference_tag, 
				                 :current_conference, :conference_name
    end

		private

		def current_conference
			@current_conference ||= Conference.find_by_subdomain!(request.subdomain)
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

	end
end