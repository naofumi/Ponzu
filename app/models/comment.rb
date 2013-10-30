# encoding: UTF-8

class Comment < ActiveRecord::Base
  attr_accessible :presentation_id, :text, :user_id
  belongs_to  :presentation, :inverse_of => :comments
  belongs_to  :user, :inverse_of => :comments
  validates_presence_of :presentation_id, :user_id, :text
  after_create :notify_authors_of_comment
  # Deprecate: We won't need it here because we will move 
  # mail body rendering to ActionMailer, where it belongs.
  include ActionView::Helpers::TextHelper
  
  include SimpleMessaging

  def notify_authors_of_comment
    send_message(:to => presentation.authors.map{|a| a.users}.flatten.compact.uniq, :mailer_method => :comment_added)
  end  

  include ConferenceRefer
  validates_conference_identity :presentation, :user
  infer_conference_from :presentation

end
