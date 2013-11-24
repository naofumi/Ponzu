class Session < ActiveRecord::Base
  attr_accessible :en_title, :ends_at, :jp_title, :organizers_string_en, :organizers_string_jp, 
                  :number, :room_id, :starts_at, :ad_category, :redirect_to
  belongs_to :room
  has_many   :presentations, :inverse_of => :session, :order => "position ASC, id ASC"
  before_destroy :validates_absence_of_presentations # in newer versions of Rails, we just add :dependent => :destroy
                                                     # https://github.com/rails/rails/pull/4727

  validates_presence_of :number
  validates_uniqueness_of :number, :scope => :conference_tag
  locale_selective_reader :title, :en => :en_title, :ja => :jp_title
  locale_selective_reader :text, :en => :en_text, :ja => :jp_text
  locale_selective_reader :organizers_string, :en => :organizers_string_en, :ja => :organizers_string_jp


  include SingleTableInheritanceMixin
  
  # Deprecated
  # Used to reject posters when preparing a time_table view
  # Should get rid of this shit as soon as possible.
  def self.poster_sessions
    Session.where("number LIKE ? OR number LIKE ?", "%P%", "%LBA%")
  end
  
  include ConferenceRefer
  validates_conference_identity :room

  # Used to display timetables.
  # Find all sessions that are being held
  # at the day of +time_object+.
  #
  # This means that the following sessions are returned.
  #
  # session_start --- day_start --- day_end --- session_end
  # day_start --- session_start --- session_end --- day_end
  # day_start --- session_start --- day_end -- session_end
  # session_start --- day_start --- session_end --- day_end
  #
  # The condition is
  #
  # day_start < session_end
  # OR
  # session_start < day_end
  def self.all_in_day(time_object)
    day_start = time_object.beginning_of_day
    day_end = 1.day.since(day_start) - 1
    self.where("? < ends_at AND starts_at < ?", 
               day_start, day_end).
         where("number != 'grid_test'") # This is a test session used when debugging grids
  end
  
  # duration in seconds
  def duration
    ends_at - starts_at
  end

  # TODO: Remove
  # Not used in a meaningful way  
  def poster?
    number =~ /^\d(P|LBA)/ ? true : false
  end
  
  alias_method :is_poster?, :poster?
  

  # Methods for ePub export
  def epub_nav_text
    "#{title} #{starts_at && starts_at.strftime('%m/%d %H:%M')}#{ends_at && ends_at.strftime('-%H:%M')}"
  end

  def order_presentations_by_number
    Presentation.transaction do
      Presentation.where(:session_id => self.id).order(:number).each.with_index do |p, i|
        errors.add(:base, p.errors.full_messages.join(', ')) unless p.update_attribute(:position, i)
      end
    end
  end

  # duration is in minutes
  def set_presentation_times_by_duration(duration)
    return if duration == 0
    Presentation.transaction do
      presentations.each.with_index do |p, i|
        p.starts_at = self.starts_at + i * duration * 60.0
        p.ends_at = self.starts_at + (i + 1) * duration * 60.0
        errors.add(:base, p.errors.full_messages.join(', ')) unless p.save
      end
    end
  end

  # as array
  def organizers
    !organizers_string.blank? ? organizers_string.split('|') : []
  end

  private

  def validates_absence_of_presentations
    unless presentations.empty?
      errors.add(:base, "Cannot delete record because dependent presentation exist")
      return false
    end
  end

end
