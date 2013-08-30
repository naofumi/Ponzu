# encoding: UTF-8

# This is a join table connecting presentations to 
# their authors.
class Authorship < ActiveRecord::Base
  attr_accessible :presentation_id, :user_id, :switch_user, :jp_name, :en_name,
                  :submission_id, :author_id, 
                  :position, :affiliations, :is_presenting_author, :affiliations_yaml
  belongs_to :submission, :inverse_of => :authorships, :touch => true
  belongs_to :author, :inverse_of => :authorships, :touch => true
  
  acts_as_list :scope => :submission

  before_save :fill_names_if_nil

  after_save :reset_whitelist_of_user

  locale_selective_reader :name, :en => :en_name, :ja => :jp_name

  validates_uniqueness_of :submission_id, :scope => :author_id

  validate :submission_and_author_conferences_must_match

  include SimpleSerializer
  serialize_array :affiliations, :typecaster => :convert_affiliations_to_integers,
                  :sort => Proc.new {|a, b| a <=> b}

  ## Methods to confirm that the current conference 
  ## is valid.
  scope :in_conference, lambda {|conference|
    includes(:submission).  # includes instead of joins to make distinct
    where(:submissions => {:conference_id => conference}).
    readonly(false)
  }

  def conference
    submission.conference
  end

  include ConferenceConfirm

  # :section: To calculate related Submissions

  # Returns an AuthorAppearances object
  # which holds information on how many times each
  # author appeared in the list of authorships.
  #
  # Deprecated because is shouldn't be Authorship centric.
  # Rather, it should be a method of Author.
  #
  # See Author#frequency_in,
  def self.author_frequency_in_authorships(authorships)
    raise "call on deprecated Authorship#author_frequency_in_authorships"
    Author.frequency_in(authorships.map{|au| au.submission})
  end

  private

  def reset_whitelist_of_user
    if changed.include?('submission_id') || 
         changed.include?('author_id')
      author.whitelisted = false
      author.whitelisted_by = 'auto'
      author.whitelisted_at = Time.now
      author.save!
    end
  end

  # params[authorships][affiliations][] will return an
  # array of strings, but we need to convert them into integers.
  def convert_affiliations_to_integers(affiliations)
    affiliations.map{|aff| aff.to_i}
  end

  def submission_and_author_conferences_must_match
    if conference != author.conference
      errors.add(:base, "Conference for Submission and Author must match.")
    end
  end

  def fill_names_if_nil
    if en_name.blank? && jp_name.blank?
      self.en_name = author.en_name
      self.jp_name = author.jp_name
    end
  end
end

