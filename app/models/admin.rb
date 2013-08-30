# Administration interface for non-resource based administration
#
# TODO: We must move this to Conference object based
class Admin
	CACHE_VERSION_FILE = "#{Rails.root}/public/system/ks_cache_version.html"
	def cache_version
		File.open(CACHE_VERSION_FILE, "r") do |f|
			return f.read
		end
	rescue
		return $!.message
	end

	def cache_version=(version_string)
		File.open(CACHE_VERSION_FILE, "w") do |f|
			f.write version_string
		end
	end
end