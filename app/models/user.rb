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
  attr_accessible :en_name, :jp_name, :twitter_id, :facebook_id, :linkedin_id, 
                  :read_research_map_id, :other_links,
                  :en_affiliation, :jp_affiliation, :author_id,
                  :email, :login, :password, :password_confirmation,
                  :read_global_messages, :registration_id_in_umin, :email_in_umin,
                  :roles, :whitelisted_by, :whitelisted_at, :whitelisted,
                  :jp_profile, :en_profile, :email_notifications, 
                  :school_search, :acad_job_search, :corp_job_search,
                  :school_avail, :acad_job_avail, :corp_job_avail,
                  :male_partner_search, :female_partner_search
  has_many :likes, :inverse_of => :user, :dependent => :restrict, :class_name => "Like::Like"
  has_many :schedules, :dependent => :destroy, :inverse_of => :user, :dependent => :restrict, :class_name => "Like::Schedule"
  # has_many  :likes, :dependent => :destroy, :inverse_of => :user, :dependent => :restrict
  # has_many  :schedules, :class_name => 'Like', :conditions => {:scheduled => true}, :dependent => :restrict
  has_many :votes, :inverse_of => :user, :dependent => :restrict, :class_name => "Like::Vote"
  has_many  :comments, :inverse_of => :user, :dependent => :restrict
  has_many  :participations, :dependent => :destroy, :inverse_of => :user, :dependent => :restrict
  has_many  :meet_ups, :through => :participations, :dependent => :restrict
  has_many  :meet_up_comments, :inverse_of => :user, :dependent => :restrict
  has_one   :registrant, :foreign_key => :registration_id, :primary_key => :login, :inverse_of => :user, :dependent => :restrict
  belongs_to  :author, :inverse_of => :users, :touch => true # Touch to update author page (add private message link)

  validates_presence_of :en_name, :if => Proc.new {|user| user.jp_name.blank? }

  before_destroy  :confirm_no_activity_before_destroy
  before_save     :set_registrant_whitelisted_by

  locale_selective_reader :name, :en => :en_name, :ja => :jp_name
  locale_selective_reader :affiliation, :en => :en_affiliation, :ja => :jp_affiliation
  locale_selective_reader :profile, :en => :en_profile, :ja => :jp_profile

  include SimpleMessaging
  include SimpleSerializer
  serialize_array :other_links
  
  acts_as_authentic do |c|
    # https://gist.github.com/436707/
    
    # c.merge_validates_format_of_login_field_options({:unless => :login_not_set?})
    # c.merge_validates_length_of_login_field_options({:unless => :login_not_set?, :is => 7})
    # c.merge_validates_uniqueness_of_login_field_options({:unless => :login_not_set?})
    
    c.merge_validates_length_of_email_field_options({:unless => :email_not_set?})
    c.merge_validates_format_of_email_field_options({:unless => :email_not_set?})
    # There seem to be cases where people are sharing email addresses. We
    # cannot assume emails to be unique.
    c.merge_validates_uniqueness_of_email_field_options({:unless => Proc.new{true}})
    # c.merge_validates_uniqueness_of_email_field_options({:unless => :email_not_set?})
    
    # c.merge_validates_confirmation_of_password_field_options({:unless => :login_not_set?})
    # c.merge_validates_length_of_password_field_options({:unless => :login_not_set?})
    # c.merge_validates_length_of_password_confirmation_field_options({:unless => :login_not_set?})

    # http://rdoc.info/github/binarylogic/authlogic/Authlogic/ActsAsAuthentic/ValidationsScope/Config
    # Scope everything to #conference_tag
    c.validations_scope = :conference_tag
  end
  

  searchable :ignore_attribute_changes_of => [User.attribute_names - 
      %w(en_name jp_name twitter_id facebook_id linkedin_id read_research_map_id other_links
         email login)].flatten.map{|a| a.to_sym} do
    text :jp_name, :en_name, :twitter_id, :email, :login

    string :conference_tag

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

  # TODO: Remove once we've migrated to conference_tag
  def find_conference
    Conference.find(conference_id)
  end


  def toggle_schedule(presentation)
    raise "Deprecated"
    l = likes.where(:presentation_id => presentation).first
    l.update_attribute(:scheduled, !l.scheduled)
  end

  # Nayose
  def mashed_up_affiliation
    if registrant && !registrant.affiliation.blank?
      registrant.affiliation
    end
  end
  
  # Mailboxer
  def receipts_by_sender_type(sender_type)
    raise "We should not be using this"
    Receipt.where(:receiver_id => self.id).
        where(:receiver_type => 'User').
        includes(:message).
        where(:notifications => {:sender_type => sender_type}).
        order("notifications.created_at DESC")
  end

  # Mailboxer
  def unread_receipts_count_by_sender_type(sender_type)
    raise "We should not be using this"
    Receipt.where(:receiver_id => self.id).
        where(:receiver_type => 'User').
        where(:read => false).
        includes(:message).
        where(:notifications => {:sender_type => sender_type}).
        count()    
  end
  
  # Mailboxer
  def receipts_to_or_from_users
    raise "We should not be using this"
    @receipts_to_or_from_users ||= begin
      result = {}
      receipts = Receipt.where(:notifications => {:sender_type => 'User'}).
                  includes(:message).
                  where('receipts.receiver_id = ? OR notifications.sender_id = ?', self.id, self.id).
                  where(:receiver_type => 'User').
                  order("notifications.created_at DESC")
      senders = User.find(receipts.map{|r| r.message.sender_id}.uniq)
      receivers = User.find(receipts.map{|r| r.receiver_id}.uniq)

      receipts.each do |r|
        correnspondant = r.receiver_id == self.id ? 
                            senders.detect{|s| s.id == r.message.sender_id} : 
                            receivers.detect{|u| u.id == r.receiver_id}
        next if correnspondant == self
        result[correnspondant] ||= []
        result[correnspondant] << r        
      end
      result
    end
  end

  # Mailboxer
  def receipts_to_or_from_user(user)
    raise "We should not be using this"
    Receipt.where(:notifications => {:sender_type => 'User'}).
            includes(:message).
            where('(receipts.receiver_id = ? OR notifications.sender_id = ?) AND ' + 
                  '(receipts.receiver_id = ? OR notifications.sender_id = ?)', 
                  self.id, self.id, 
                  user.id, user.id).
            where(:receiver_type => 'User').
            order("notifications.created_at DESC")
  end

  # Mailboxer
  def receipts_from_users
    raise "We should not be using this"
    @receipts_from_users ||= begin
      result = {}

      # We do this because we can't preload polymorphic associations
      receipts = receipts_by_sender_type('User')
      senders = MeetUp.find(receipts.map{|r| r.message.sender_id}.uniq)

      receipts_by_sender_type('User').each do |r|
        # sender = r.message.sender
        sender = senders.detect{|s| s.id == r.message.sender_id}

        result[sender] ||= []
        result[sender] << r
      end
      result
    end
  end

  # Mailboxer
  def unread_receipts_from_users_count
    raise "We should not be using this"
    unread_receipts_count_by_sender_type('User')
  end

  # Mailboxer
  def receipts_from_meet_ups
    raise "We should not be using this"
    @receipts_from_meet_ups ||= begin
      result = {}

      # We do this because we can't preload polymorphic associations
      receipts = receipts_by_sender_type('MeetUp')
      senders = MeetUp.find(receipts.map{|r| r.message.sender_id}.uniq)

      receipts_by_sender_type('MeetUp').each do |r|
        # sender = r.message.sender
        sender = senders.detect{|s| s.id == r.message.sender_id}
        result[sender] ||= []
        result[sender] << r
      end
      result
    end
  end

  # Mailboxer
  def unread_receipts_from_meet_ups_count
    raise "We should not be using this"
    unread_receipts_count_by_sender_type('MeetUp')
  end

  # Mailboxer
  def receipts_from_comments
    raise "We should not be using this"
  end


  # Mailboxer
  def receipts_from_presentations
    raise "We should not be using this"
    @receipts_from_presentations ||= receipts_by_sender_type('Presentation')
  end

  # Mailboxer
  def mailboxer_email(object)
    raise "We should not be using this"
    # object is either a Message or Notification
    # We can use this to select which notifications should
    # be sent out to which address.
    # https://github.com/ging/mailboxer
    if Rails.env == "production"
      if login_active? && !email.blank?
        email
      else
        nil
      end
    elsif Rails.env == "development" || Rails.env == "development_nayose" ||
          Rails.env == "staging"
      nil
      # "naofumi@castle104.com"
    elsif Rails.env == "test"
      nil
    else
      "naofumi@castle104.com"
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
  
  # # === For automatic namesake whitelisting
  # # If the user has a single affiliation string in all Umin records,
  # # then we can confidently say that this is a single person.
  # # Hence we automatically whitelist him/her.
  # # Otherwise, the user requires manual whitelisting.
  # def whitelist_if_consistent_affiliation
  #   if unique_umin_name_and_affiliation_combos.size <= 1
  #     self.whitelisted = true
  #     self.whitelisted_by = 'auto'
  #     self.whitelisted_at = Time.new
  #     self.blacklisted = false
  #     self.blacklisted_by = 'auto'
  #     self.blacklisted_at = Time.new
  #     self.save!
  #   end
  # end
  
  # === For automatic namesake whitelisting
  # Automatically whitelist all User objects
  # def self.auto_whitelist_all
  #   i = 0
  #   User.find_each do |u|
  #     puts "auto_whitelisting #{i}th User with id #{u.id}"
  #     u.whitelist_if_consistent_affiliation
  #     i += 1
  #   end
  # end


  # def blacklisted_by_user(status, user)
  #   if status
  #     self.blacklisted_by = user.name
  #     self.blacklisted_at = Time.now
  #   end
  #   self[:blacklisted] = status
  # end

  # Copy registration_id_in_umin to login
  # and email_in_umin to password, password_confirmation to activate
  # login for user.
  # Due to duplicate registration_ids, and the suspicion that the
  # registration_ids are not accurate, we will only activate after
  # we are sure.
  # DEPRECATED!!! This is not how we login.
  # def activate_login!
  #   self.login = registration_id_in_umin
  #   self.password = email_in_umin
  #   self.password_confirmation = email_in_umin
  #   save!
  # end

  # def activate_by!(args)
  #   login_id = args[:login]
  #   password = args[:password]
  #   self.login = login_id
  #   self.password = password
  #   self.password_confirmation = password
  #   save!
  # end
  
  # def login_active?
  #   login.blank? ? false : true
  # end
  
  # registrant_whitelist_status
  # Database is integer
  # We return as symbols
  def registrant_whitelist_status
    case read_attribute(:registrant_whitelist_status)
    when 0
      :grey
    when -1
      :black
    when 1
      :white
    else
      raise "Registrant whitelist status value is not -1, 0, 1"
    end
  end

  def registrant_whitelist_status=(status)
    case status
    when :grey
      write_attribute(:registrant_whitelist_status, 0)
    when :black
      write_attribute(:registrant_whitelist_status, -1)
    when :white
      write_attribute(:registrant_whitelist_status, 1)
    else
      raise "Registrant whitelist status value is not :grey, :black, :white"
    end
    save!
  end

  def toggle_registrant_whitelist_status
    current = registrant_whitelist_status
    statuses = [:grey, :white, :black]
    next_status = statuses[(statuses.index(current) + 1).modulo(3)]
    self.registrant_whitelist_status = next_status
    save!
  end

  ## Roles for CanCan
  # add new roles on right end to preserve previous settings
  ROLES = %w[admin user_moderator organizer voter sponsor]
  
  def roles=(roles)
    self.roles_mask = (roles & ROLES).map{|r| 2**ROLES.index(r)}.sum
  end
  
  def roles
    ROLES.reject{|r| ((roles_mask || 0) & 2**ROLES.index(r)).zero?}
  end
  
  def role?(role)
    roles.include? role.to_s
  end
  
  scope :with_role, lambda {|role|
    role_query_mask = 2**User::ROLES.index(role)
    where("roles_mask & ? != 0", role_query_mask)
  }


  # Interface for mailboxer
  def avatar
    "default_avatar.png"
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
    
  def email_not_set?
    email.blank?
  end

  def confirm_no_activity_before_destroy
    # It's likely that this won't work because the associations will
    # be destroyed before before_destroy is called. Hence
    # we set the restriction in the association definition :dependent => :restrict
  end

  def set_registrant_whitelisted_by
    if changed.include? 'registrant_whitelist_status'
      self.registrant_whitelisted_by = UserSession.find && UserSession.find.record.name
    end
  end
end
