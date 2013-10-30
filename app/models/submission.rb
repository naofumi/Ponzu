# encoding: utf-8

class Submission < ActiveRecord::Base
  attr_accessible :disclose_at, :en_abstract, :en_title, :jp_abstract, :jp_title, 
                  :main_author_id, :presenting_author_id, :submission_number,
                  :institutions, :keywords, :type

  has_many  :presentations, :inverse_of => :submission, :dependent => :destroy


  # Apparently, Presentation.touch does not fire
  # after_save, and Presentation.save does not fire
  # after_touch. Pretty confusing.
  after_touch do
    presentations.each {|p| p.touch}
  end
  after_save do
    presentations.each {|p| p.touch}
  end

  has_many    :authors, :through => :authorships, :inverse_of => :submissions
  has_many    :authorships, :dependent => :destroy, :inverse_of => :submission


  locale_selective_reader :title, :ja => :jp_title, :en => :en_title
  locale_selective_reader :abstract, :ja => :jp_abstract, :en => :en_abstract

  validates_presence_of :submission_number
  validates_uniqueness_of :submission_number, :scope => :conference_tag

  include SimpleSerializer
  serialize_array :institutions, :class => "Institution", 
                                 :typecaster => :hash_to_institution
  serialize_array :keywords

  include ConferenceRefer

  # TODO: Remove after we add conference_tag attributes
  def find_conference
    Conference.find(conference_id)
  end

  def first_author
    @first_author ||= begin
      authors.where(:authorships => {:position => 0}).first
    end
  end

  def presenting_author
    @presenting_author ||= begin
      authors.where(:authorships => {:is_presenting_author => true}).first
    end
  end

  def is_presenting_author?(user)
    user == presenting_author
  end
    
  def authorships_by_same_authors
    # SELECT *, COUNT(*) AS count FROM authorships WHERE authorships.user_id 
    # IN [1,3,5,6] GROUP BY presentation_id;
    @authorships_by_same_authors ||= Authorship.select("*, COUNT(*) AS count").
                                      where('author_id' => authors.map{|a| a.id}).
                                      group(:submission_id).order("count DESC")
  end
  
  def submissions_by_same_authors
    @submissions_by_same_authors ||= begin
      submissions = Submission.includes(:authors).
                                   where(:id => authorships_by_same_authors.
                                                map{|a| a.submission_id})
      # Uses authorships_by_same_authors to sort the submissions
      authorships_by_same_authors.map{|a| 
        submissions.detect{|s| s.id == a.submission_id}
      }
    end
  end

  private

  def hash_to_institution(institutions_as_params)
    if institutions_as_params.first && institutions_as_params.first.is_a?(Hash)
      return institutions_as_params.
              map{|inst_param|
                unless inst_param[:en_name].blank? && inst_param[:jp_name].blank?
                  Institution.new :en_name => inst_param[:en_name],
                                  :jp_name => inst_param[:jp_name]
                else
                  nil
                end
              }.compact
    else
      return institutions_as_params
    end
  end
end
