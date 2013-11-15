module Kamishibai
  module LocaleSupport
    
    def self.included(base)
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
        I18n.locale = negotiated_locale
        cookies[:locale] = {value: negotiated_locale,
                            expires: 3.months.from_now}
      end
    end

  end
end