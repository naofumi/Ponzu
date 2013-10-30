# encoding: UTF-8

class MeetUpComment < ActiveRecord::Base
  attr_accessible :content, :meet_up_id
  belongs_to  :meet_up, :inverse_of => :meet_up_comments
  belongs_to  :user, :inverse_of => :meet_up_comments
  validates_presence_of :meet_up_id, :user_id
  # after_save   :notify_participants_of_changes

  include ConferenceRefer
  validates_conference_identity :user, :meet_up
  infer_conference_from :meet_up
  
end
