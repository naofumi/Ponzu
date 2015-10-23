module I18nHelper
  def t(*args)
    if args.last.kind_of? Hash
      args.last.merge!(:namespace => current_conference.tag) unless args.last[:namespace]
    else
      if respond_to? :current_conference
        args.push({:namespace => current_conference.tag})
      else
        raise "Must specify :namespace in #t unless respond to #current_conference"
      end
    end
    translate(*args)
  end

  # Temporarily change the locale to 'en' if the condition argument is true.
  # Use when there is a per session or per presentation policy to use
  # a certain language to display a presentation, even when the session
  # itself contains mulilingual data.
  def temporarily_force_en_locale(condition = true)
    if condition
      locale_stash = I18n.locale
      I18n.locale = 'en'
      yield
      I18n.locale = locale_stash
    else
      yield
    end
  end
end
