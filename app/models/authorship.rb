# encoding: UTF-8

# This is a join table connecting presentations to 
# their authors.
#
# Unlike previous version (before NGS2015), Authorships were created only 
# by the batch system and administrators.
#
# Since NGS2015, we introduced a Registration inteface for normal users
# which means we need to do a lot of validations.
class Authorship < ActiveRecord::Base
  attr_accessible :presentation_id, :user_id, :switch_user, :jp_name, :en_name,
                  :submission_id, :author_id, 
                  :position, :affiliations, :is_presenting_author, :affiliations_yaml,
                  :_sync_author_names

  # `_sync_author_names` triggers the `sync_author_if_requested_and_only_authorship_on_author` method
  # which makes sure that the Author name and Authorship are in sync (but only if there is only one Authorship)
  # for that Author.
  attr_accessor :_sync_author_names
  belongs_to :submission, :inverse_of => :authorships, :touch => true
  belongs_to :author, :inverse_of => :authorships, :touch => true
  after_destroy :destroy_author_if_orphan
  
  acts_as_list :scope => :submission

  validates_presence_of :submission_id
  validates_presence_of :en_name
  validates_presence_of :affiliations_string

  # The email address is currently a dummy and we don't do anything with it.
  # It was introduced for NGS2015.
  validates_presence_of :email
  validates_format_of :email, :with => Authlogic::Regex.email

  validate :affiliation_institutes_are_set

  before_validation :fill_conference_tag_if_nil
  before_save :fill_names_if_nil
  before_save :uniquify_affiliations

  before_save :create_author_if_absent

  after_save :sync_author_if_requested_and_only_authorship_on_author

  locale_selective_reader :name, :en => :en_name, :ja => :jp_name

  validates_uniqueness_of :submission_id, :scope => :author_id

  # validate :submission_and_author_conferences_must_match

  include SimpleSerializer
  serialize_array :affiliations, :typecaster => :convert_affiliations_to_integers,
                  :sort => Proc.new {|a, b| a <=> b}

  include ConferenceRefer
  validates_conference_identity :author, :submission
  infer_conference_from :submission

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

  def looking_for_job?
    author.looking_for_job?
  end

  def looking_for_person?
    author.looking_for_person?
  end

  def looking_for_partner?
    author.looking_for_partner?
  end

  def affiliations_string
    affiliations.join(",")
  end

  def affiliations_string= (string)
    self.affiliations = string.split(/,/).map{|n| n.strip}
  end

  private

  # params[authorships][affiliations][] will return an
  # array of strings, but we need to convert them into integers.
  #
  # Furthermore, this removes any blank strings which are used
  # in a hidden field to circumvent the "value not sent if none-checked" issue.
  def convert_affiliations_to_integers(affiliations)
    affiliations.map{|aff| aff.to_i if !aff.blank?}.compact
  end

  # def submission_and_author_conferences_must_match
  #   if conference != author.conference || conference != submission.conference
  #     errors.add(:base, "Conference for Authorship, Submission and Author must match.")
  #   end
  # end

  def fill_names_if_nil
    if en_name.blank? && jp_name.blank?
      self.en_name = author.en_name
      self.jp_name = author.jp_name
    end
  end

  def fill_conference_tag_if_nil
    if conference_tag.nil?
      if ct = submission.conference_tag || author.conference_tag
        self.conference_tag = ct
      end
    end
  end

  def create_author_if_absent
    if author_id.nil?
      a = Author.new(:en_name => en_name, :jp_name => jp_name)
      a.conference_tag = conference_tag
      # We have to skip validations on Author because Author will
      # validate for the presence of a Submission, which we can 
      # only give it after saving an Authorship.
      a.save(:validate => false)
      self.author = a
      # We need a reload so that author recognizes its Authorships
      author.reload
    end
  end

  def uniquify_affiliations
    self.affiliations = affiliations.uniq
  end

  def destroy_author_if_orphan
    if author.authorships.empty?
      author.destroy
    end
  end

  def affiliation_institutes_are_set
    institutions_count = submission.institutions.size
    affiliations.each do |affiliation|
      unless institutions_count >= affiliation && affiliation > 0
        errors.add(:affiliations_string, "は所属に含まれていない番号があります。")
        break
      end
    end
  end

  def sync_author_if_requested_and_only_authorship_on_author
    if author && author.authorships.size == 1 && _sync_author_names
      # Inside a callback, it's better to not use stuff that
      # triggers validations, etc. unless we're sure that we want to
      # do it. 
      # 1. `update_attributes!` will fire RecordInvalid exceptions but
      #    these tend to be consumed in `transaction` blocks and will not
      #    always be raised up to where we want them to be.
      # 2. If we want to raise an exception, we should raise something explicit
      #    and that will not be consumed in `transaction` blocks. These blocks
      #    are lurking in may unexpected places.
      # 3. If you are fiddling with an association, ActiveModel::Errors will
      #    not automatically be set on the current object (but on the object you're working with).
      #    Error handling becomes complicated.
      author.update_column(:en_name, en_name)
      author.update_column(:jp_name, jp_name)
    end
  end
end

