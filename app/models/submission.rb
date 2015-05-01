# encoding: utf-8

class Submission < ActiveRecord::Base

  attr_accessible :disclose_at, :en_abstract, :en_title, :jp_abstract, :jp_title, 
                  :main_author_id, :presenting_author_id, :submission_number,
                  :institutions, :keywords, :type, :external_link, :confirmed
  attr_accessor   :do_not_validate_title_abstract_lengths, :do_not_strip_unallowed_tags,
                  :skip_authorships_and_institutions_validations

  before_destroy :confirm_absence_of_presentations_before_destroy

  has_many  :presentations, :inverse_of => :submission, :dependent => :destroy

  # TODO: Strongly coupled to the existence of the RegistrationEngine.
  #       Not a good idea
  if Kernel.const_defined?(:Registration)
    belongs_to  :submission_category_1, :class_name => "Registration::SubmissionCategory", 
                :foreign_key => "registration_category_id_1", :inverse_of => :submissions_1

    belongs_to  :submission_category_2, :class_name => "Registration::SubmissionCategory", 
                :foreign_key => "registration_category_id_2", :inverse_of => :submissions_2

    belongs_to  :submission_category_3, :class_name => "Registration::SubmissionCategory", 
                :foreign_key => "registration_category_id_3", :inverse_of => :submissions_3
  end

  before_save :strip_unallowed_html_tags

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

  include BatchImportMixin
  if Kernel.const_defined?(:Registration)
    validate :must_have_submission_category_1, :unless => "batch_import || !conference.config('registration_enabled')"
  end
  validate :must_have_at_least_one_authorship, :unless => "skip_authorships_and_institutions_validations || batch_import"
  validate :must_have_at_least_one_institution, :unless => "skip_authorships_and_institutions_validations"

  validates_presence_of :disclose_at

  validate :check_title_abstract_lengths

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

  def check_title_abstract_lengths
    # In certain cases (e.g. Admin is entering the abstract for keynote speakers)
    # we don't want this validation to be run.
    # In these cases we can just set @do_not_validate_title_abstract_lengths
    unless @do_not_validate_title_abstract_lengths
      length_restrictions = conference.config("length_restrictions")
      if length_restrictions && (configs = length_restrictions["submission"])
        configs.each do |key, value|
          # We don't want to validate on a trivial change like updating timestamps
          next unless changed.include?(key.to_s)
          string = send(key) || ""
          html_stripped_string = ActionController::Base.helpers.strip_tags(string)
          # textareas in browsers may use two characters per linebreak.
          # We don't want this.
          html_stripped_string = html_stripped_string.gsub(/\r\n/, "\n")
          if value && html_stripped_string.size > value
            errors.add(key, "が長すぎます")
          end
        end
      end
    end
  end

  def strip_unallowed_html_tags
    unless @do_not_strip_unallowed_tags
      [:en_title, :jp_title].each do |attribute|
        # Make sure we don't inadvertently change on a trivial change like updating timestamps
        next unless changed.include?(attribute.to_s)
        allowed_tags = conference.config(:allowed_tags_in_submission_title) || %w(b i u sup sub)
        string = send(attribute)
        if string && (sanitized_string = ActionController::Base.helpers.sanitize(string, :tags => allowed_tags))
          send("#{attribute}=", sanitized_string)
        end
      end

      [:en_abstract, :jp_abstract].each do |attribute|
        # Make sure we don't inadvertently change on a trivial change like updating timestamps
        next unless changed.include?(attribute.to_s)
        allowed_tags = conference.config(:allowed_tags_in_submission_abstract) || %w(b i u sup sub br)
        allowed_attributes = conference.config(:allowed_attributes_in_submission_abstract) || %w(href)
        string = send(attribute)
        if string && (sanitized_string = ActionController::Base.helpers.sanitize(string, :tags => allowed_tags, :attributes => allowed_attributes))
          send("#{attribute}=", sanitized_string)
        end
      end
    end
  end

end
