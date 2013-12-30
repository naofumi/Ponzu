module Ponzu
	module MultiConference
		def self.included(base)
			base.helper_method :conference_module, :conference_tag, 
				                 :current_conference, :conference_name
			base.before_filter :redirect_unless_conference_found
    end

		private

		# Detects the current conference by subdomain.
		# If in development or test environment, 
		# it will return the first conference if one 
		# corresponding to the subdomain is not found.
		# This allows us to use domain names like localhost
		# during development.
		# 
		# In reality, when we are seriously developing, we are unlikely
		# to use this feature. It's mostly to allow enthusiasts to
		# check out the open source version.
		def current_conference
			@current_conference ||= begin
				Conference.find_by_subdomain(request.subdomain) ||
				((Rails.env == "development" || Rails.env == "test") && Conference.first )
			end
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