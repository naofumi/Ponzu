class UserSession < Authlogic::Session::Base
	attr_accessor :conference_confirm
	validate :user_must_belong_to_conference_confirm

	private

	# We scope login_ids by conference_tag so that we can
	# have two users belonging to difference conferences and sharing
	# the same login_id
	# http://anjantek.com/2011/07/25/authlogic-segregate-scope-and-authenticate-users-by-category-or-company-or-account-and-scope-by-deleted/
	# https://github.com/binarylogic/authlogic/blob/master/lib/authlogic/session/scopes.rb
	def user_must_belong_to_conference_confirm
		if conference_confirm && user.conference != conference_confirm
			errors.add(:base, "User does not belong to conference #{conference_confirm.name}")
		end
	end
end