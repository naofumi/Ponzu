# encoding: UTF-8

# This is by far the biggest class that we have in Ponzu.
# It does a ton of stuff. We want to separate it into Concerns.
#
# A lot of this is Nayose and Mailboxer related.

# The User object handles all user related tasks.
#
# It is used for authentication, and it also holds the authors
# of each presentation.
#
# We generate the Users from UMIN data dump, which means that
# the users initially will not have email addresses and passwords
# set. 
#
# === The scheme
# https://gist.github.com/436707/
# 
# We initially create user accounts without any login credentials.
#
# If the user is a registered attendee, then we assign login credentials based
# on their attendee ID. We also send them their password (which we generate) via email.
# We only confirm their credentials if they have an attendee ID.
# We won't use email/token based systems because of potential issues.
#
# MBSJ 2011 login credentials;
# ログインID：参加登録ID（34から始まる7桁の数字）
# ログインパスワード：オンライン事前参加登録時に登録したEメールアドレス
# 当日参加はたぶんパスワードを自動生成か何かしたんじゃないかな。
#
# === Identical names
# We collect and associate names aggressively, almost assuming that identical
# names for different people exist. We then look at the affiliation information
# manually, to identify identical names.
#
# The system will automatically collect users which have conflicting affiliations.
# These people might actually be a sum of two people with identical names.
# In most cases, they are not. We whitelist these people after manual inspection.
# When the presentations associated with this user changes (an authorship related
# to this person is created), then we reset the whitelist.
#
# We will provide batch methods to automatically whitelist users with only
# one set of affiliations. We will also provide views that list non-whitelisted
# users.
#
# In 

class User < ActiveRecord::Base
  include SingleTableInheritanceMixin

  attr_accessible :en_name, :jp_name, :twitter_id, :facebook_id, :linkedin_id, 
                  :read_research_map_id, :other_links,
                  :en_affiliation, :jp_affiliation, :author_id,
                  :email, :email_confirmation, :login, :password, :password_confirmation,
                  :read_global_messages, :registration_id_in_umin, :email_in_umin,
                  :roles, :whitelisted_by, :whitelisted_at, :whitelisted,
                  :jp_profile, :en_profile, :email_notifications, 
                  :school_search, :acad_job_search, :corp_job_search,
                  :school_avail, :acad_job_avail, :corp_job_avail,
                  :male_partner_search, :female_partner_search,
                  :submission_info, :other_attributes, :registration_confirmed, :email_confirmed

  PERSONAL_FIELDS = %w(login_count failed_login_count last_request_at current_login_at
                      last_login_at current_login_ip last_login_ip crypted_password
                      password_salt persistence_token perishable_token
                      email_notifications login_activated_at)
  has_many :likes, :inverse_of => :user, :dependent => :restrict, :class_name => "Like::Like"
  has_many :schedules, :dependent => :destroy, :inverse_of => :user, :dependent => :restrict, :class_name => "Like::Schedule"
  # has_many  :likes, :dependent => :destroy, :inverse_of => :user, :dependent => :restrict
  # has_many  :schedules, :class_name => 'Like', :conditions => {:scheduled => true}, :dependent => :restrict
  has_many :votes, :inverse_of => :user, :dependent => :restrict, :class_name => "Like::Vote"
  has_many  :comments, :inverse_of => :user, :dependent => :restrict
  has_many  :participations, :dependent => :destroy, :inverse_of => :user, :dependent => :restrict
  has_many  :meet_ups, :through => :participations, :dependent => :restrict
  has_many  :meet_up_comments, :inverse_of => :user, :dependent => :restrict

  belongs_to  :author, :inverse_of => :users

  has_many  :submissions, :dependent => :restrict, :inverse_of => :user

  before_save :update_registration_confirmed_at

  # Fields which don't affect how user information is displayed to other users.
  # Updates to these fields will not touch #author and will not invalidate
  # the caches depending on #author.
  def after_save(record)
    if !(record.changed_attributes.keys - PERSONAL_FIELDS).empty?
      record.author.touch
    end
  end

  # Only validate user after a login ID has been assigned.
  # Before that, they will only have :email and :password set.
  # Because we want different validation rules for subclasses,
  # we restrict it to the User class.
  validates_presence_of :en_name, 
                        :if => Proc.new {|user| user.class == User && user.jp_name.blank? }
  validates :email, confirmation: true


  before_destroy  :confirm_no_activity_before_destroy

  locale_selective_reader :name, :en => :en_name, :ja => :jp_name
  locale_selective_reader :affiliation, :en => :en_affiliation, :ja => :jp_affiliation
  locale_selective_reader :profile, :en => :en_profile, :ja => :jp_profile

  include SimpleMessaging
  include SimpleSerializer
  serialize_array :other_links
  serialize_single :other_attributes
  
  # Authentication and permission concerns (authlogic and CanCan)
  include User::Authentication

  def flags
    result = []
    [ :school_search, :acad_job_search, :corp_job_search,
      :school_avail, :acad_job_avail, :corp_job_avail,
      :male_partner_search, :female_partner_search].each do |attribute|
      result << attribute if self[attribute]
    end
    result
  end

  SOLR_IGNORE_ATTRIBUTES = PERSONAL_FIELDS
  # Since Authlogic changes attributes related to login info, we
  # ideally want to ignore `updated_at`. However, we also use
  # `updated_at` for russian-doll caching so we need it to 
  # update the SOLR cache.
  #
  # Our current compromise is to NOT ignore `updated_at`. This
  # means that we are updating SOLR cache unnecessarily.
  searchable :ignore_attribute_changes_of => SOLR_IGNORE_ATTRIBUTES.map{|a| a.to_sym} do
    text :jp_name, :en_name, :twitter_id, :email, :login

    string :conference_tag

    string :flags, :multiple => true, :stored => true
    string :in_categories, :multiple => true, :stored => true do
      if author
        author.in_categories
      else
        []
      end
    end
    # TODO: use Submission to do this.
    # text :authorship_affiliations do
    #   author && author.authorships.includes(:submissions).map {|au|
    #     institution_indices = au.affiliations
    #     au.presentation.institutions_umin.select{|inst| 
    #       institution_indices.include?(inst[:institution_number])
    #     }.map{|inst|
    #       [inst[:en_name], inst[:jp_name]]
    #     }
    #   }.flatten.uniq.join(' | ')
    # end
  end

  include ConferenceRefer

  # Nayose
  def mashed_up_affiliation
    if registrant && !registrant.affiliation.blank?
      registrant.affiliation
    end
  end
    
  ############## FOR importing ##########
  
  
  # Used within a rake task for quality control purposes
  # Don't use this in automated assignment, because the query
  # might be too broad
  def find_similar_by_name
    return [self] if en_name.blank?
    User.where("(en_name LIKE ? AND en_name LIKE ?) OR " + 
               "(en_name LIKE ? AND en_name LIKE ?)",
               "#{split_en_name.first}%", "%#{split_en_name.last}",
               "#{split_en_name.last}%", "%#{split_en_name.first}").all
  end

  def find_similar_by_jp_name
    return [self] if jp_name.blank?
    User.where("(jp_name LIKE ? AND jp_name LIKE ?) OR " + 
               "(jp_name LIKE ? AND jp_name LIKE ?)",
               "#{split_jp_name.first}%", "%#{split_jp_name.last}",
               "#{split_jp_name.last}%", "%#{split_jp_name.first}").all

  end

  def split_en_name
    @split_en_name ||= begin
      splitted = en_name.split(/[ 　（）\(\)]+/)
      Struct.new(:first, :last).new(splitted.first, splitted.last)
    end
  end

  def split_jp_name
    @split_jp_name ||= begin
      splitted = jp_name.split(/[ 　（）\(\)]+/)
      Struct.new(:first, :last).new(splitted.first, splitted.last)
    end
  end


  ############# end for importing ##################
    
  def author_id=(string)
    if string =~ /authors\/(\d+)/
      self[:author_id] = $1
    else
      self[:author_id] = string
    end
  end


  ## Other attributes
  def attribute_for(attribute_symbol)
    attribute_symbol = attribute_symbol.to_s
    if other_attributes && other_attributes[attribute_symbol]
      return other_attributes[attribute_symbol]
    else
      return nil
    end
  end

  # Set the attribute using self.other_attributes= so that
  # it will become dirty and tagged for update
  def set_attribute_for(attribute_symbol, value)
    attribute_symbol = attribute_symbol.to_s

    my_other_attributes = self.other_attributes || {}
    my_other_attributes[attribute_symbol] = value
    self.other_attributes = my_other_attributes
  end

  def thread_message
    "#{name}さんからのメッセージ"
  end
  
  def next_non_whitelisted_user_by_id
    User.where("users.id > ?", id).order("users.id ASC").where(:whitelisted => false).where(:blacklisted => false).first
  end

  def next_user_by_id
    User.where("users.id > ?", id).order("users.id ASC").first
  end

  def previous_user_by_id
    User.where("users.id < ?", id).order("users.id DESC").first
  end

  def previous_non_whitelisted_user_by_id
    User.where("users.id < ?", id).order("users.id DESC").where(:whitelisted => false).where(:blacklisted => false).first
  end

  def twitter_url
    !twitter_id.blank? ? "https://mobile.twitter.com/#{twitter_id.sub(/^@/, '')}" : nil
  end

  def facebook_url
    !facebook_id.blank? ? "https://m.facebook.com/#{facebook_id.sub(/^.+facebook\.com\//, '')}" : nil
  end

  def linkedin_url
    !linkedin_id.blank? ? "http://#{linkedin_id.sub(/^https?:\/\//, '')}" : nil
  end
    
  private

  def confirm_no_activity_before_destroy
    # It's likely that this won't work because the associations will
    # be destroyed before before_destroy is called. Hence
    # we set the restriction in the association definition :dependent => :restrict
  end

  def update_registration_confirmed_at
    if (changed.include?("registration_confirmed") || new_record?) && registration_confirmed
      self.registration_confirmed_at = Time.now
    end
  end
end
