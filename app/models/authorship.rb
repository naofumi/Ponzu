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
  attr_accessor :skip_affiliations_validation

  # `_sync_author_names` triggers the `sync_author_if_requested_and_only_authorship_on_author` method
  # which makes sure that the Author name and Authorship are in sync (but only if there is only one Authorship)
  # for that Author.
  attr_accessor :_sync_author_names
  belongs_to :submission, :inverse_of => :authorships, :touch => true
  belongs_to :author, :inverse_of => :authorships, :touch => true
  after_destroy :destroy_author_if_orphan
  
  acts_as_list :scope => :submission

  include BatchImportMixin

  validates_presence_of :submission_id
  validate :name_is_set
  validates_presence_of :affiliations_string, 
                        :unless => Proc.new{|authorship| 
                                              authorship.skip_affiliations_validation == true ||
                                              authorship.author && (authorship.author.batch_import == true) ||
                                              authorship.submission && (authorship.submission.batch_import == true)
                                            }

  # The email address is currently a dummy and we don't do anything with it.
  # It was introduced for NGS2015.
  validates_presence_of :email, if: :require_email_in_authorships
  validates_format_of :email, :with => Authlogic::Regex.email, if: :require_email_in_authorships

  validate :affiliation_institutes_are_set
  validate :en_name_format
  validate :jp_name_format

  before_validation :fill_conference_tag_if_nil
  before_validation :fill_names_if_nil
  before_validation :uniquify_affiliations

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
        if (batch_import || author && author.batch_import || submission && submission.batch_import)
          raise "Bad affiliations_string for submission: #{submission.institutions.inspect} author: #{author.name} affiliations: #{affiliations.join(',')}"
        end
        errors.add(:affiliations_string, "は所属に含まれていない番号があります。")
        break
      end
    end
  end

  def name_is_set
    if en_name.blank? && jp_name.blank?
      errors.add(:en_name, "英語名もしくは日本語名は必須です。")
    end
  end

  def en_name_format
    if conference.config('validate_name_format_in_authorships')
      if (en_name.present? && en_name !~ /^(?:\p{Latin}|[-\.,\(\) ])+$/)
        errors.add(:en_name, "はアルファベット以外の文字が含まれまれています。")
      end
      if (en_name.present? && en_name !~ /[ ]/)
        errors.add(:en_name, "はfirst nameとlast nameをスペースで区切ってください。")
      end      
    end
  end

  def jp_name_format
    if conference.config(:validate_name_format_in_authorships)
      if (jp_name.present? && jp_name !~ /[ 　]/)
        errors.add(:jp_name, "は姓と名をスペースで区切ってください。")
      end
    end
  end

  def sync_author_if_requested_and_only_authorship_on_author
    if author && author.authorships.size == 1 && _sync_author_names
      # Inside a callback, you should be better use persistence
      # methods that will always work. This is because they won't
      # raise errors for you unless you are explicit.
      #
      # For example, using #save! in a callback will raise a RecordInvalid exception
      # but if the record was saved with #save, then that will consume
      # the RecordInvalid exception. You simply cannot expect the exception
      # to bubble up reliably, so the best you can do is to add an ActiveModel::Errors,
      # which can be a bit complicated in it's own right if we are doing nested stuff.
      # 
      # If we want to raise an error, raise something explicit. Otherwise,
      # make sure that the callback won't fail.
      #
      # You could also test if the return value is nil, but that's not always good.
      author.update_column(:en_name, en_name)
      author.update_column(:jp_name, jp_name)
    end
  end

  def require_email_in_authorships
    return !!conference.config('require_email_in_authorships')
  end
end

