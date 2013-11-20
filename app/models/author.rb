# encoding: utf-8
require_relative "../../lib/locale_reader"
require 'set'

# Author objects represent an Author of a Submission. Author
# objects are separate from User objects. User objects
# represent a User who can log into the system. On the
# other hand, Author objects are simply data that has
# been extracted from the Submissions.
#
# This is very different from the MBSJ2012 system. In the 
# MBSJ2012, we did not have Author objects but instead
# User objects served both roles (which was confusing).
#
# == Author objects do not contain Twitter IDs, etc.
#
# That stuff should be put into User objects.
#
# == Relationship with User objects.
#
# Author - User is a one-to-many relationship. This means
# that an Author may be associated with multiple Users.
#
# Ideally, an author should only have one user, but sometimes it doesn't work out that way.
# In the MBSJ2012, registration ID handout was confused so we had multiple registrants
# per author, and we had to consolidate those.
#
# In the new Ponzu, we decided not to consolidate. Instead, the system will merge information
# from multiple Users when we display the Author profile.
class Author < ActiveRecord::Base
  attr_accessible :en_name, :jp_name, :en_name_clean, :jp_name_clean, 
                  :whitelisted, :initial_submission, :initial_authorship

  attr_accessor :initial_submission, :initial_authorship

  has_many  :users, :inverse_of => :author
  has_many  :authorships, :inverse_of => :author, :dependent => :destroy
  has_many  :submissions, :through => :authorships, :inverse_of => :authors
  has_many  :presentations, :through => :submissions, :inverse_of => :authors

  locale_selective_reader :name, :en => :en_name, :ja => :jp_name
  validate :either_en_name_or_jp_name_must_be_present
  validate :has_at_least_one_submission

  before_validation :assign_initial_submission
  before_validation :assign_initial_authorship

  include ConferenceRefer
  validates_conference_identity :authorships, :submissions#, :users, :presentations
  infer_conference_from :authorships, :submissions

  begin
    include Nayose::Finders
    include Nayose::Whitelisting
  rescue
  end

  # Authors receive messages from Presentation and Comment objects.
  # The messages are sent to all the User objects associated with the Author.
  include SimpleMessaging

  # searchable :ignore_attribute_changes_of => ["updated_at"],
  #            :unless => proc {|model| model.authorships.empty? } do
  searchable :ignore_attribute_changes_of => ["updated_at"],
             :unless => proc {|model| model.authorships.empty? } do
    text :jp_name, :en_name

    text :authorship_en_name do
      authorships.map{|au| au.en_name}.uniq.join(' | ')
    end
    text :authorship_jp_name do
      authorships.map{|au| au.jp_name}.uniq.join(' | ')
    end

    string :conference_tag

    # TODO: use Submission to do this.
    # text :authorship_affiliations do
    #   author && author.authorships.includes(:submissions).map {|au|
    #     institution_indices = au.affiliations
    #     au.presentation.institutions_umin.select{|inst| 
    #       institution_indices.include?(inst[:institution_number])
    #     }.map{|inst|
    #       [inst[:en_name], inst[:jp_name]]
    #     }
    #   }.flatten.uniq.join(' | ')
    # end
  end

  # Deprecated: only until we set the conference_tag attribute
  def find_conference
    submissions.first.conference
  end

  # Takes an array of objects, each of which
  # responds to an #authors method.
  # 
  # Counts the number of times each
  # individual Author was found in the
  # result of #authors.
  #
  # We use this to highlight authors
  # in a list of Submission or Presentation
  # objects.
  def self.frequency_in(objects)
    appearances = Appearances.new
    objects.each do |obj|
      obj.authors.each do |a|
        appearances.increment(a)
      end
    end
    appearances
  end


  def all_unique_affiliations
    all_unique_affiliations_as_array.map{|a| a.join(' ')}
  end

  def all_unique_affiliations_as_array
    result = [].to_set
    authorships.each do |as|
      as.affiliations.each do |aff|
        institute = as.submission.institutions[aff - 1]
        unless institute
          # Sometimes the institute info will not yet be filled in
          STDERR.puts "WARNING: institute[#{aff}] not entered for submission #{as.submission.submission_number}"
        else
          result << [institute.en_name, institute.jp_name]
        end
      end
    end
    result
  end

  def unique_authorship_name_and_affiliation_combos
    result = [].to_set
    authorships.each do |as|
      combo = ["#{as.jp_name} #{as.en_name}"]
      as.affiliations.each do |aff|
        institute = as.submission.institutions[aff - 1]
        unless institute
          # Sometimes the institute info will not yet be filled in
          STDERR.puts "WARNING: institute[#{aff}] not entered for submission #{as.submission.submission_number}"
        else
          combo << "#{institute.jp_name}　#{institute.en_name}"
        end
      end
      result << combo.join(' ## ')
    end
    result
  end

  def unique_affiliation_combos
    result = [].to_set
    authorships.each do |as|
      combo = []
      as.affiliations.each do |aff|
        institute = as.submission.institutions[aff - 1]
        unless institute
          # Sometimes the institute info will not yet be filled in
          STDERR.puts "WARNING: institute[#{aff}] not entered for submission #{as.submission.submission_number}"
        else
          combo << "#{institute.jp_name} #{institute.en_name}"
        end
      end
      result << combo.join(' ## ')
    end
    result
  end

  # Evaluates to true if the current Author has a common co-author
  # with other_authors.
  #
  # We use this to assess whether two authors that have similar
  # names are actually the same person or not.
  def has_common_coauthor_with(other_authors)
  end

  def looking_for_job?
    !!users.detect{|u| 
      u.school_search || 
      u.acad_job_search ||
      u.corp_job_search
    }
  end

  def looking_for_person?
    !!users.detect{|u| 
      u.school_avail || 
      u.acad_job_avail ||
      u.corp_job_avail
    }
  end

  def looking_for_partner?
    !!users.detect{|u| 
      u.male_partner_search || 
      u.female_partner_search
    }
  end

  private

  def either_en_name_or_jp_name_must_be_present
    errors.add(:en_name, "Either en_name or jp_name must be set") if en_name.blank? && jp_name.blank?
    errors.add(:jp_name, "Either en_name or jp_name must be set") if en_name.blank? && jp_name.blank?
  end

  def has_at_least_one_submission
    if submissions.empty? && authorships.empty?
      errors.add :base, "Must have at least one submission for Author #{id}"
    end
  end

  def assign_initial_submission
    if !initial_submission.blank? && submissions.empty?
      self.submissions = [Submission.find(initial_submission)]
    end
  end

  def assign_initial_authorship
    if !initial_authorship.blank? && submissions.empty?
      self.authorships = [Authorship.find(initial_authorship)]
    end
  end
end
