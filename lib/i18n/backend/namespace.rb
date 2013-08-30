# 
module I18n
	module Backend
		module Namespace
			def lookup(locale, key, scope = [], options = {})
				return super unless namespace = options.delete(:namespace)
				scope = I18n.normalize_keys(nil, key, scope)
				key   = scope.pop
				namespaced_scope = [namespace] + scope
				if namespaced_result = super(locale, key, namespaced_scope, options)
					return namespaced_result
				else
					return super(locale, key, scope, options)
				end
			end
		end
	end
end