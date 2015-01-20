# encoding: utf-8

class Submission < ActiveRecord::Base
  attr_accessible :disclose_at, :en_abstract, :en_title, :jp_abstract, :jp_title, 
                  :main_author_id, :presenting_author_id, :submission_number,
                  :institutions, :keywords, :type, :external_link, :confirmed

  before_destroy :confirm_absence_of_presentations_before_destroy

  has_many  :presentations, :inverse_of => :submission, :dependent => :destroy

  # TODO: Strongly coupled to the existence of the RegistrationEngine.
  #       Not a good idea
  belongs_to  :submission_category_1, :class_name => "Registration::SubmissionCategory", 
              :foreign_key => "registration_category_id_1", :inverse_of => :submissions_1

  belongs_to  :submission_category_2, :class_name => "Registration::SubmissionCategory", 
              :foreign_key => "registration_category_id_2", :inverse_of => :submissions_2

  belongs_to  :submission_category_3, :class_name => "Registration::SubmissionCategory", 
              :foreign_key => "registration_category_id_3", :inverse_of => :submissions_3

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
  accepts_nested_attributes_for :authorships, :reject_if => :all_blank, :allow_destroy => true

  belongs_to  :user, :inverse_of => :submissions

  locale_selective_reader :title, :ja => :jp_title, :en => :en_title
  locale_selective_reader :abstract, :ja => :jp_abstract, :en => :en_abstract

  validates_presence_of :submission_number
  validates_uniqueness_of :submission_number, :scope => :conference_tag

  validate :must_have_title
  validate :must_have_submission_category_1
  validate :must_have_at_least_one_authorship
  validate :must_have_at_least_one_institution

  validates_presence_of :disclose_at

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

  def confirm_absence_of_presentations_before_destroy
    if self.presentations.size > 0
      errors.add(:presentations, " must be empty before destroy")
      return false
    end
  end

  def must_have_title
    if title.blank?
      errors.add(:en_title, :blank)
    end
  end

  def must_have_submission_category_1
    if submission_category_1.blank?
      errors.add(:registration_category_id_1, :blank)
    end
  end

  def must_have_at_least_one_authorship
    if authorships.empty?
      errors.add(:authorships, :empty)
    end
  end

  def must_have_at_least_one_institution
    if institutions.empty?
      errors.add(:institutions, :empty)
    end
  end

end
