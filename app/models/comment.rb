# encoding: UTF-8

# Replies to comments are threaded using acts_as_nested_set.
# We create replies by creating a new Comment object with the 
# parent object set to the original Comment (or the parent_id to the original Comment id).
class Comment < ActiveRecord::Base
  attr_accessible :presentation_id, :text, :user_id, :parent_id
  acts_as_nested_set :counter_cache => :child_count, :order_column => "rgt DESC"
  belongs_to  :presentation, :inverse_of => :comments, :touch => true
  belongs_to  :user, :inverse_of => :comments
  before_validation :fill_presentation_id_from_parent_id
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

  private

  def fill_presentation_id_from_parent_id
    if parent_id && !presentation_id
      self.presentation_id = parent.presentation_id
    end
  end

end
