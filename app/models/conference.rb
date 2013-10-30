class Conference < ActiveRecord::Base
  attr_accessible :dates, :module_name, :support_email, :name, :tag, 
                  :database_tag, :subdomain, :send_all_emails_to, :icons, 
                  :conference_home_page_url, :ks_cache_version
  include SimpleSerializer
  serialize_single :dates, :typecaster => :remove_blank_from_conference_dates
  serialize_single :icons, :typecaster => :remove_blank_from_icons

  has_many :users, :foreign_key => :conference_tag, 
           :primary_key => :database_tag, :dependent => :restrict
  # http://rdoc.info/github/binarylogic/authlogic/Authlogic/AuthenticatesMany
  # Scope users by Conference
  authenticates_many :user_sessions

  # We prefer to use Submissions.in_conference(current_conference)
  # instead of current_conference.submissions in the controller.
  # This allows us to use the same query regardless of object
  #
  # has_many :submissions, :inverse_of => :conference, :dependent => :restrict
  # has_many :sessions, :inverse_of => :conference, :dependent => :restrict
  # has_many :meet_ups, :inverse_of => :conference, :dependent => :restrict
  # has_many :rooms, :inverse_of => :conference, :dependent => :restrict
  # has_many :global_messages, :inverse_of => :conference, :dependent => :restrict
  include ConferenceDates

  # Converts the unserialized icons (strings) into symbols
  def icons_as_sym(key_as_string)
    if icons && icons[key_as_string].any?
      icons[key_as_string].map{|i| i.to_sym}
    else
      []
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

end
