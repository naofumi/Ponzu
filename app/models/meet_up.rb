# encoding: UTF-8

class MeetUp < ActiveRecord::Base
  attr_accessible :description, :meet_at, :starts_at, :venue, 
                  :venue_url, :title, :starts_at_date, :starts_at_hour, 
                  :starts_at_minute, :interest, :venue_phone, :owner_phone
  has_many :participations, :dependent => :destroy, :inverse_of => :meet_up
  has_many :participants, :through => :participations, :source => :user
  belongs_to :owner, :class_name => 'User'

  has_many :meet_up_comments, :inverse_of => :meet_up, :dependent => :destroy
  validates_presence_of :owner_id, :title
  before_validation :set_starts_at
  validates_presence_of :starts_at
  after_save   :notify_participants_of_changes

  include ConferenceRefer
  validates_conference_identity :owner

  include ConferenceDates
    
  def starts_at_date
    starts_at && starts_at.strftime('%Y-%m-%d')
  end
  
  def starts_at_date= (date)
    @starts_at_date = date
    # starts_at.change(:day => day)
  end
  
  def starts_at_hour
    starts_at && (starts_at.hour)
  end

  def starts_at_hour= (hour)
    @starts_at_hour = hour.to_i
  end
  
  def starts_at_minute
    starts_at && starts_at.min
  end

  def starts_at_minute= (minute)
    @starts_at_minute = minute.to_i
  end
  
  def set_starts_at
    if @starts_at_date && @starts_at_hour && @starts_at_minute
      self.starts_at = Time.zone.parse("#{@starts_at_date}").
                       change(:hour => @starts_at_hour.to_i,
                              :min => @starts_at_minute.to_i)
    end
  end
  
  def venue_url=(url)
    if url !~ /^http/
      url = "http://" + url
    end
    self[:venue_url] = url
  end

  def toggle_participation(user)
    participate?(user) ? participants.destroy(user) :
                         participants << user
  end
  
  def participate?(user)
    user && participants.include?(user)
  end

  def participation_for_user(user)
    user && participations.detect{|p| p.user == user}
  end
  
  def notify_participants_of_changes
    # send_message (participants + users_who_commented - [owner]).uniq, changes_message, "Yorusemi #{self.title} was changed"
    # send_message owner, changes_message, "Yorusemi #{self.title} was changed"
  end
  
  def users_who_commented
    meet_up_comments.map{|c| c.user}
  end
  
  def changes_message
    [ "Title: #{title}",
      "Starts at: #{starts_at.strftime('%m/%d %H:%M')}",
      "Place: #{venue}",
      "Owner: #{owner.name}",
      "Owner contact: #{owner_phone}",
      "Place URL: #{venue_url}",
      "Place phone: #{venue_phone}",
      "Description: #{description}"].join("\n")
  end
  
  # Interface for mailboxer
  def name
    title
  end
end
