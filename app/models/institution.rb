class Institution
  include LocaleReader
  attr_accessor :en_name, :jp_name
  locale_selective_reader :name, :en => :en_name, :ja => :jp_name

  def initialize(options = {})
    options.each do |key, value|
      if [:en_name, :jp_name].include?(key.to_sym)
        send("#{key}=".to_sym, value)
      end
    end
  end

end