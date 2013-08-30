require 'test_helper'

class I18nBackendNamespaceTest < ActiveSupport::TestCase
	def setup
	end

	test "get namespaced translation" do
		# If :namespace is set, find namespaced translation and use it
		assert_equal "Generic Conference Test Translation",
		             I18n.translate('test_translation', :namespace => 'generic_conference')
		# If :namespace is not set, find translation and use it
		assert_equal "Test Translation",
		             I18n.translate('test_translation')
		# If :namespace is set, but namespaced translation is not available,
		# use non-namespaced version.
		assert_equal "Test Translation no Namespace only",
		             I18n.translate('test_translation_no_namespace_only', :namespace => 'generic_conference')
	end
end