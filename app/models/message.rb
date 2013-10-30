class Message < ActiveRecord::Base
  attr_accessible :body, :sender_id, :sender_type, :subject
  belongs_to :sender, :polymorphic => true
  has_many  :receipts, :inverse_of => :message, :dependent => :destroy
  validates_presence_of :sender

  # TODO: We can get rid of the below now because we
  # can refer directly to conference_tag.
  #
  # We can't create an #in_conference scope to select all 
  # messages in a conference, because the path to the objects
  # that have a #conference_id attribute has a polymorphic
  # association (you can't join on polymorphic associations)
  #
  # We work around by creating more customized queries.
  # (look at the private_message_controller for more)
  # def conference
  #   sender.conference
  # end

  include ConferenceRefer
  validates_conference_identity :sender
  infer_conference_from :sender

end
