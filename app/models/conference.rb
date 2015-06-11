# class Conference
#
# This class holds the information used to configure each conference differently
# and to separate the contents.
#
# We originally stored the configurations in database fields.
#
# However, we are now moving away from this. We are moving to storing configurations
# in config/conferences.yml
# This will allow more flexibile configuration.
#
# Additionally, by including Conference::ConferenceSpecificModules, we can 
# detect the presence of any modules or classes that are conference specific.
# For example, instead of doing a `User.create()`, you can use 
# `current_conference.user_class.create()` which (if User::[current_conference_tag] is defined),
# will return a user object of User::[current_conference_tag] instead of User.
# You can then add conference specific methods in User::[current_conference_tag].
#
# Of course you should set up single table inheritance to ensure that 
# you will always get a User::[current_conference_tag] object instead of User.
class Conference < ActiveRecord::Base
  attr_accessible :dates, :module_name, :support_email, :name, :tag, 
                  :database_tag, :subdomain, :send_all_emails_to, :icons, 
                  :conference_home_page_url, :ks_cache_version,
                  :available_locales, :timetable_hour_labels
  include SimpleSerializer
  serialize_single :dates, :typecaster => :remove_blank_from_conference_dates
  serialize_single :icons, :typecaster => :remove_blank_from_icons
  serialize_array  :available_locales, :typecaster => :remove_blank_from_locales

  has_many :users, :foreign_key => :conference_tag, 
           :primary_key => :database_tag, :dependent => :restrict
  # http://rdoc.info/github/binarylogic/authlogic/Authlogic/AuthenticatesMany
  # Scope users by Conference
  authenticates_many :user_sessions

  attr_accessor :delegate

  include ConferenceDates

  include Conference::ConferenceSpecificModules

  after_initialize :initialize_conference

  def initialize_conference
    begin
      # module_name will not exist for new conference.
      if module_name
        self.delegate = "Conference::#{module_name}".constantize.new
      end
    rescue NameError
      self.delegate = nil
    end
  end

  # Converts the unserialized icons (strings) into symbols
  def icons_as_sym(key_as_string)
    if icons && icons[key_as_string].any?
      icons[key_as_string].map{|i| i.to_sym}
    else
      []
    end
  end

  def timetable_hours(show_date = nil)
    # raise config('timetable_hour_labels').inspect
    if show_date &&
       config('timetable_hour_labels').present? &&
       (hour_labels = config('timetable_hour_labels')[show_date.strftime('hours_%Y%m%d')])
      hour_labels
    elsif timetable_hour_labels.present?
      JSON.parse(timetable_hour_labels)
    else
      [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19]
    end
  end

  # Instead of storing all configuration information in the database,
  # we are thinking of moving stuff to YAML files in "/config/conferences/[conference_tag].yml".
  # This is because we want flexible configuration without migrating the database or designing views.
  # Also, storing stuff that we won't change in the database is rather nonsensical.
  def config(config_symbol)
    if config_hash[tag]
      config_hash[tag][config_symbol.to_s]
    else
      nil
    end
  end


  def config_hash
    @@config_hash ||= begin
      yaml_path = File.join(Rails.root, "config", "conferences.yml")
      Psych.load_file(yaml_path)
    end
  end

  def support_email
    if config(:support_email).present?
      config(:support_email)
    else
      read_attribute(:support_email)
    end
  end

  private

  def remove_blank_from_conference_dates(dates)
  	dates.each do |key, value|
  		dates[key] = dates[key].select{|e| !e.blank?}
  	end
  	return dates
  end

  def remove_blank_from_icons(icons)
    icons.each do |key, value|
      icons[key] = icons[key].select{|e| !e.blank?}
    end
    return icons
  end

  def remove_blank_from_locales(locales)
    locales.select{|l| !l.blank?}
  end

end
