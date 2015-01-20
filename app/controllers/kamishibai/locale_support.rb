module Kamishibai
  module LocaleSupport

    
    def self.included(base)
      base.before_filter :set_default_locale
      base.before_filter :set_locale

      base.extend(ClassMethods)
    end

    module ClassMethods
    end

    # helper_method :ksp
    private

    def set_locale
      available_locales = current_conference.available_locales
      negotiated_locale = http_accept_language.compatible_language_from(available_locales)
      if !cookies[:locale].blank? &&
            available_locales.include?(cookies[:locale])
        I18n.locale = cookies[:locale]
      else
        I18n.locale = negotiated_locale ? negotiated_locale : available_locales.first
        cookies[:locale] = {value: I18n.locale,
                            expires: 3.months.from_now}
      end
    end

    # The default locale is the locale used when 
    # the :locale cookie is not yet set.
    #
    # The `set_locale` method uses the locale in the
    # browser settings, but sometimes we want to override that.
    def set_default_locale
      if !cookies[:locale] && (default_locale = current_conference.config(:default_locale))
        cookies[:locale] = default_locale
      end
    end

  end
end