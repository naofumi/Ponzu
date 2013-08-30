# encoding: UTF-8

class Comment < ActiveRecord::Base
  attr_accessible :presentation_id, :text, :user_id
  belongs_to  :presentation, :inverse_of => :comments
  belongs_to  :user, :inverse_of => :comments
  validates_presence_of :presentation_id, :user_id, :text
  validate :presentation_and_user_conferences_must_match
  after_save :send_message_to_authors
  # Deprecate: We won't need it here because we will move 
  # mail body rendering to ActionMailer, where it belongs.
  include ActionView::Helpers::TextHelper
  
  include SimpleMessaging

  def send_message_to_authors
    send_message(:to => presentation.authors.map{|a| a.users}.flatten.compact.uniq, :mailer_method => :comment_added)
  end  

  ## Methods to confirm that the current conference 
  ## is valid.
  scope :in_conference, lambda {|conference|
    # http://stackoverflow.com/questions/639171/what-is-causing-this-activerecordreadonlyrecord-error
    includes(:presentation => :submission).  # includes instead of joins to make distinct
    where(:submissions => {:conference_id => conference}).
    readonly(false)
  }

  def conference
    presentation.submission.conference
  end

  include ConferenceConfirm

  private

  def presentation_and_user_conferences_must_match
    if presentation.submission.conference != user.conference
      errors.add(:base, "Conference for Presentation and User must match.")
    end
  end
end
