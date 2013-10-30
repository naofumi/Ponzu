# encoding: UTF-8

class Participation < ActiveRecord::Base
  attr_accessible :meet_up_id, :user_id
  belongs_to :meet_up
  belongs_to :user
  # after_save :notify_owner_of_participant
  # before_destroy :notify_owner_of_removal
  
  include ConferenceRefer
  validates_conference_identity :meet_up, :user
  infer_conference_from :meet_up, :user
end
