# encoding: utf-8

# LocaleReader#locale_selective_reader defines an readable accessor
# which selects from a set of accessors based on the current locale (I18n.locale)
#
# For example, if we have
#
#   class Presentation
#     locale_selective_reader :title, :ja => :jp_title, :en => :en_title
#   end
#
# then @presentation.title will return @presentation.jp_title if <tt>I18n.locale == :ja</tt>
# and return @presentation.en_title if <tt>I18n.locale == :en</tt>.
module LocaleReader
  CHARACTERS_TO_DELETE = ['　+']
  FUNNY_CHARACTERS = []

  def LocaleReader.included(base)
    base.extend ClassMethods
  end
    

  module ClassMethods
    # When the method +attribute_name+ is called, it will call
    # methods in the _options_ attribute based on the current locale.
    #
    #   locale_selective_reader :title, :ja => :jp_title, :en => :en_title
    #
    # or
    #
    #   locale_selective_reader :abstract, 
    #                           :ja => :jp_abstract, :en => :en_abstract, 
    #                           :zap_gremlins => true
    def locale_selective_reader(attribute_name, options)
      define_method attribute_name do
        should_zap_gremlins = options.delete(:zap_gremlins)
        raw = choose_by_locale(options)
        if should_zap_gremlins
          raw && raw.gsub(regexp, '')
        else
          raw
        end
      end
    end
  end

  private

  def zap_gremlins(string)
    regexp = Regexp.new(FUNNY_CHARACTERS.join('|'))
    string && string.gsub(regexp, '')
  end

  def choose_by_locale(options)
    raise "value for :en locale is a requirement" unless options[:en]
    raise "value for :ja locale is a requirement" unless options[:ja]
    stash = {}
    options.each do |key, value|
      stash[key] = send(value)
    end

    case I18n.locale
    when :ja
      !stash[:ja].blank? ? stash[:ja] : stash[:en]
    when :en
      !stash[:en].blank? ? stash[:en] : stash[:ja]
    else
      !stash[:ja].blank? ? stash[:ja] : stash[:en]
    end
  end
end

class ActiveRecord::Base < Object
  include LocaleReader
end