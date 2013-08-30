class AdminController < ApplicationController
	authorize_resource

	def cache_version
		if request.get?
			@cache_version = Admin.new.cache_version
			# File.open("#{Rails.root}/public/ks_cache_version.html", "r") do |f|
			# 	@cache_version = f.read
			# end
		elsif request.post?
			@cache_version = params[:cache_version]
			Admin.new.cache_version = @cache_version
			flash[:notice] = "Updated cache version"
			# File.open("#{Rails.root}/public/ks_cache_version.html", "w") do |f|
			# 	f.write @cache_version
			# 	flash[:notice] = "Updated cache version"
			# end
		end
	end
end
