# encoding: UTF-8

class MeetUpComment < ActiveRecord::Base
  attr_accessible :content, :meet_up_id
  belongs_to  :meet_up, :inverse_of => :meet_up_comments
  belongs_to  :user, :inverse_of => :meet_up_comments
  validates_presence_of :meet_up_id, :user_id
  # after_save   :notify_participants_of_changes
  validate :meet_up_and_user_conferences_must_match

  ## Methods to confirm that the current conference 
  ## is valid.
  scope :in_conference, lambda {|conference|
    includes(:meet_up). # for distinct results
    where(:meet_ups => {:conference_id => conference})
  }

  def conference
  	meet_up.conference
  end

  include ConferenceConfirm
  
  private

  def meet_up_and_user_conferences_must_match
    if conference != user.conference
      errors.add(:base, "Conference for MeetUpComment and User must match.")
    end
  end
  
end
