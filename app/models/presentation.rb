  # encoding: UTF-8

# This is the base class for Presentation subclasses. We use 
# single-table-inheritance to manage all the subclasses of Presentation.
#
# == Subclassing Presentations into Poster, Forum, Booth, Seminar, Workshop, Symposium, etc.
# 
# We have subclassed Presentations. The Presentation object is first subclassed into
# Mappable and TimeTableable. These represent presentations that are done at at location 
# (Posters and Booths) and those done at a specific time (Forums, Workshops, Symposia, Seminars). 
# These presentations tend to have different requirements. For example, Mappable presentations
# have a tag that represents the location (for a Poster, we use a substring of the presentation
# number. For Booths, we will have to create a specific field). On the other hand, TimeTableable
# presentations will calculate ends_at times based on when the next Presentation starts (because
# ends_at will not generally be directly inputted, but rather needs to be calculated). We use
# Rails single-table-inheritance for this. The benefit is that we can separate the code for each 
# type of Presentation, and we can easily mix and match behaviours by changing the inheritance or adding mixins.
# 
# By dividing Mappable into Posters, and Booths we can handle the mapping differently. Poster
# mapping will tend to be simple because the presentation number directly indicates the
# position of the poster. Poster sizes are also uniform. For booths, the situation is much
# more complicated. Most likely, we will create a grid system for booths, and each booth will
# contain a list of which grids it encompasses.
class Presentation < ActiveRecord::Base
  include SingleTableInheritanceMixin

  belongs_to  :submission, :inverse_of => :presentations
  delegate    :en_title, :jp_title, :main_author_id, :title,
              :disclose_at, :en_abstract, :jp_abstract, :abstract,
              :keywords, :corresponding_email, :show_email, :submission_number,
              :institutions,
              :to => :submission

  attr_accessible :ends_at, 
                  :number, :session_id, :starts_at,
                  :position, :submission_id,
                  :type, :cancel

  belongs_to :submitter, :class_name => User
  has_many    :authorships, :through => :submission
  has_many    :authors, :through => :authorships

  belongs_to  :session, :inverse_of => :presentations, :touch => true
  acts_as_list :scope => :session
  has_many :likes, :inverse_of => :presentation, :dependent => :destroy, :class_name => "Like::Like"
  has_many :schedules, :inverse_of => :presentation, :dependent => :destroy, :class_name => "Like::Schedule"
  has_many :votes, :inverse_of => :presentation, :dependent => :destroy, :class_name => "Like::Vote"

  # has_many  :likes, :inverse_of => :presentation, :dependent => :destroy

  has_many  :comments, :dependent => :destroy, :inverse_of => :presentation

  validates_presence_of :session
  validates_presence_of :submission
  validate     :start_and_end_should_be_within_session_ranges

  # after_save   :notify_likers_of_changes


  include SimpleMessaging
  
  # maximum number of likes to show for a user that is not 
  # an author. (we limit to prevent stalkers)
  LIKE_SHOW_LIMIT = 500

  include ActionView::Helpers::SanitizeHelper

  searchable :unless => proc {|model| !model.session} do
    text :jp_abstract, :stored => true, :more_like_this => true do
      strip_tags(jp_abstract) unless cancel
    end
    # On more_like_this 
    # http://cephas.net/blog/2008/03/30/how-morelikethis-works-in-lucene/
    text :en_abstract, :stored => true, :more_like_this => true do
      strip_tags(en_abstract) unless cancel
    end
    text :en_title, :stored => true, :more_like_this => true do
      strip_tags(en_title) unless cancel
    end
    text :jp_title, :stored => true, :more_like_this => true do
      strip_tags(jp_title) unless cancel
    end
    text :number, :stored => true
    text :session_number, :stored => true do
      session.number
    end
    text :session_title, :stored => true do
      session.title
    end

    time :starts_at

    string :type
    
    text :authors, :stored => true do
      authors.includes(:authorships).inject([]){|memo, a|
        memo << [a.en_name, a.jp_name]
        memo << a.authorships.map{|auth|
          [auth.en_name, auth.jp_name]
        }
      }.flatten.compact.uniq.join(' | ') unless cancel
    end

    integer :session_id

    integer :conference_id do
      submission.conference_id
    end
  end
  
  ## Methods to confirm that the current conference 
  ## is valid.
  scope :in_conference, lambda {|conference|
    includes(:submission). # for distinct results
    where(:submissions => {:conference_id => conference}).
    readonly(false)
  }

  def conference
    # We use session instead of submission to get the conference
    # object, because we often use the session#presentations
    # association to get many presentations. These presentation
    # objects will have the Session object set via :inverse_of
    # and hence will not need a database request.
    @conference ||= session.conference
  end

  include ConferenceConfirm


  # We are currently using this to set menus. We should change
  # this to set the menu based on Class. This way, we can manage
  # menus for Exhibitions with the same function
  def is_poster?
    kind_of? Presentation::Poster
  end
      
  def next
    lower_item
  end

  def previous
    higher_item
  end
  
  def presentations_belonging_to_same_submission
    submission.presentations - [self]
  end

  def presentations_by_same_authors_but_different_submissions
    (submission.submissions_by_same_authors - [submission]).compact.
      map{|s| s.presentations}.compact.uniq.flatten
  end

  def number_with_other_presentations
    if presentations_belonging_to_same_submission.any?
      number + " (" +
      presentations_belonging_to_same_submission.map{|p| p.number}.join(', ') +
      ")"
    else
      number
    end
  end
  # TODO: This is a hack and we need to get rid of it
  # def timetable_or_poster_session_string
  #   if poster_row_id
  #     "/#{I18n.locale}/poster_sessions/#{poster_row_id[0,1]}"
  #   else
  #     starts_at ? "/#{I18n.locale}/timetable/#{starts_at.strftime('%Y-%m-%d')}" : ""
  #   end
  # end

  # TODO: This is a hack and we need to get rid of it
  def timetable_or_poster_session_fragment_id
    if poster_row_id
      "backdrop_#{poster_row_id[0,1]}"
    else
      "timetable_#{starts_at.strftime('%Y-%m-%d')}"
    end
  end
  
    
  private

  # Notify users who like this Presentation when something has changed.
  def notify_likers_of_changes # :doc:
    if !likes.empty?
      likers = likes.map{|l| l.user}
      send_message(:to => likers, :mailer_method => :presentation_modified)
    end
  end
  
  def start_and_end_should_be_within_session_ranges
    if session && starts_at
      errors.add(:starts_at, " must after session starts_at") unless session.starts_at <= starts_at
    end
    # if session && ends_at
    #   errors.add(:ends_at, " must after session starts_at") unless session.ends_at >= ends_at
    # end
  end

end

