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
      I18n.locale = :en
      # if cookies[:locale].blank?
      #   cookies[:locale] = I18n.default_locale
      # end
      # I18n.locale = cookies[:locale]
    end

    # http://edgeguides.rubyonrails.org/i18n.html#setting-the-locale-from-the-client-supplied-information
    # def extract_locale_from_accept_language_header
    #   request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
    # end
  end
end