# encoding: UTF-8

# The Like is a join table that implements the 「いいね！」
# function. It connects a presentation to a user.
#
# Another idea is to connect submissions to users. In this case,
# a like on a Oral presentation will also result in a like on the Poster
# presentation.
#
# However, since we currently use the same Like object for 
# both my_schedules and likes, this will be a problem. If we used
# a like for both the oral and poster presentations, then
# the Submission will appear on both schedules.
#
# == Single-table inheritance of Like
#
# To make it easier to accomodate cases where we want MySchedule
# and Like to be independent, and also cases where we want to extend
# Like into a voting system, we use single table inheritance.
#
# For example, to implement the MBSJ2012 case where we need to 
# Like before we can add to my schedule, the inheritance will
# be as follows.
#
#     class Like::Like < Like; end # a Like
#     class Like::Schedule < Like::Like; end # a My Schedule
#
#     @likes = Like::Like.where(:user_id => current_user.id)
#     @schedules = Like::Schedule.where(:user_id => current_user.id)
#
# Since Like::Like is the superclass of Like::Schedule, Like::Like.all
# will include Like::Schedules in the search result.
#
# On the other hand, if we want the Like and Schedule to be indepent,
# then we code as follows.
#
#     class Like::Like < Like; end # a Like
#     class Like::Schedule < Like; end # a My Schedule
#
#     @likes = Like::Like.where(:user_id => current_user.id)
#     @schedules = Like::Schedule.where(:user_id => current_user.id)
#
# Since Like::Like and Like::Schedule are indepedent classes, the Active::Record
# queries will be independent.
#
# To implement a voting system that is independent of Like::Like, we could
# do the following.
#
#     class Like::Like < Like; end # a Like
#     class Like::Schedule < Like::Like; end # a My Schedule
#     class Like::Vote < Like; end # a Like
#
#     @likes = Like::Like.where(:user_id => current_user.id)
#     @schedules = Like::Schedule.where(:user_id => current_user.id)
#     @votes = Like::Vote.where(:user_id => current_user.id)
#
# In JSDB2013, each vote was either rated as 'excellent' or a 'unique'.
# To implement this, we could add a field #score as an integer. We
# could use this #score as a numeric score, or use it as a qualitative
# flag indicating 'excellent' or 'unique'. We could use single table inheritance
# like Like::Excellent and Like::Unique, but this is clearly an overkill.
#
# The associations on Presentation and User will be as follows;
#
#     class Presentation
#       has_many :likes, :inverse_of => :presentation, :dependent => :destroy, :class_name => "Like::Like"
#     end
#
#     class User
#       has_many :likes, :dependent => :destroy, :inverse_of => :user, :dependent => :restrict, :class_name => "Like::Like"
#       has_many :schedules, :dependent => :destroy, :inverse_of => :user, :dependent => :restrict, :class_name => "Like::Schedule"
#     end
#
# In the future, we should refactor and rename +class Like+ into something
# like +class Rate+.
class Like < ActiveRecord::Base
  include SingleTableInheritanceMixin

  attr_accessible :presentation_id, :user_id, :scheduled, :type
  validates_presence_of :presentation_id
  validates_presence_of :user_id
  validates_uniqueness_of :presentation_id, :scope => [:user_id, :type]
  belongs_to :user, :inverse_of => :likes
  belongs_to :presentation, :inverse_of => :likes
  # validate :presentation_and_user_conferences_must_match

  scope "timetableable", lambda {
    where('presentations.type IN (?)', Presentation::TimeTableable.descendants.map{|d| d.to_s})
  }
        

  scope "mappable", lambda {
    where('presentations.type IN (?)', Presentation::Mappable.descendants.map{|d| d.to_s})
  }
        

  scope "presentation_on", lambda {|date|
    where('presentations.starts_at > ? AND presentations.starts_at < ?', date.beginning_of_day, date.end_of_day)
  }

  def scheduled
    raise "Deprecated use of #scheduled. Use single table inheritance instead."
  end

  # include ConferenceConfirm

  include ConferenceRefer
  infer_conference_from :presentation, :user
  validates_conference_identity :presentation, :user


  private
  
  # def presentation_and_user_conferences_must_match
  #   if presentation.submission.conference != user.conference
  #     errors.add(:base, "Conference for Presentation and User must match.")
  #   end
  # end

end
