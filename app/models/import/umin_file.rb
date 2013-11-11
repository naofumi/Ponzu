require 'set'

# Import documentation::
#   Documentation about the import process is found in the classes under Import.
#   Read those docs to get a better understanding.
# = Importing data from UMIN
#
# Unfortunately, we will still have to import data from UMIN-ish data sources.
# This can get really complicated. Let's make sure that we sort it out.
#
# We want to do the whole session very deliberately. We will divide into 
# many steps. 
#
# 1. Creating Author objects.
# 2. Creating Submission objects.
# 3. Creating Authorship objects (joining together the Authors and the Submissions).
# 4. Creating Session objects (if session information is available)
# 5. Creating Presentation objects (joining together the Submissions and the Sessions).
#
# == Batch Import must be non-destructive
#
# As a strict rule, all batch import methods must be non-destructive. That is, batch
# import should never overwrite manual edits. We must be 100% confident that a 
# batch import will only add information and never overwrite our manual edits.
#
# There will be cases however where we want batch updates. For example, we might 
# want to batch update presentation numbers. In these cases, we should create a
# separate method that does only this. Even so, I think it would be better to
# use an interactive shell so that we can confirm each update.
#
# == Use reports instead of overwriting data
#
# Since we have made the batch imports non-destructive, when we recieve a new version
# of the UminFile and we run the batch import tasks, some of the data is not going
# to be automatically updated. In particular, editing of preexisting submissions
# will not happen for the majority of the cases.
#
# This is a fundamental limitation of having two different interfaces for editing data;
# UMIN and Ponzu. A submission might be edited via UMIN by the submitter, or it may
# be edited inside Ponzu by an administrator. The only way to resolve any conflicts is
# to use manual confirmation.
#
# To aid confirmation, we generate reports. One of these reports is a Diff rake task.
# This will tell you the difference between any two versions of a UMIN file. If
# you find any edits on pre-existing submissions in the Diff report, then make
# sure that the changes have been applied using the web interface.
#
# TODO: We might also add a task to diff against the data in the database.
#
# == Nayose
#
# === Nayose of Authors
#
# This involves joining and separating Authors. This inevitably requires us to move
# Authorships around as well.
#
# When we create the Authors, we try to combine similar Authors into the same
# object. Hence the first Nayose step is separation.
#
# We first ..
#
# When we have sufficiently separated an Author, then we flag it as +single_person_confirmed+.
# All Authors that have only one Authorship are automatically set to +single_person_confirmed+.
#
#
# If at a later date, we add an Authorship to this Author, then we remove the flag.
module Import
  # Import documentation::
  #   Documentation about the import process is found in the classes under Import.
  #   Read those docs to get a better understanding.
  #
  # A list of the methods that constitute the interface between the importing 
  # class (UminFile) and the parser (UminParser subclasses).
  #
  # Only the methods specified here will be accessible from the UminFile importer.
  #
  # This interface will also be used when we generate a diff in Import::UminFile.diff.
  #
  # This module is referenced from RowWrapper#def_delegators and Import::UminFile#compare_values.
  module ParserInterface
    # View source to see the methods that must be implemented in the Parser.
    def self.interface_methods
      [:submission_number, :disclose_at, :title_en, :title_jp,
       :jp_abstract, :en_abstract, :institutions, :keywords,
       :session_room_en_name, :session_room_jp_name, :session_room_jp_location,
       :session_room_en_location, :session_number, :session_starts_at,
       :session_ends_at, :session_en_title, :session_jp_title, :organizers_string_en,
       :organizers_string_jp, :session_type, :presentation_type, :starts_at,
       :number_string, :authors]
    end
  end

  # Import documentation::
  #   Documentation about the import process is found in the classes under Import.
  #   Read those docs to get a better understanding.
  #
  # Wraps a UminParser instance so that only the specified methods are exposed.
  # This also tells us that these are the methods that we have to implement
  # (the interface) for each UminParser.
  #
  # The methods that constitute the interface are defined in 
  # ParserInterface::interface_methods
  class RowWrapper
    extend Forwardable

    def_delegators :@parser_obj, *ParserInterface::interface_methods

    def initialize(obj)
      @parser_obj = obj
    end
  end
  # Import documentation::
  #   Documentation about the import process is found in the classes under Import.
  #   Read those docs to get a better understanding.
  #  
  # A Umin File. Each Umin File has its own special format. We therefore
  # delegate parsing to a UminParser. 
  #
  # === Batch import
  #
  # The UminFile class handles batch parsing
  # of all the rows in a file. A full import session would consist of the
  # following methods run in sequence.
  # 
  # Each batch import method is non-destructive, which means that it should
  # never overwrite manual edits. This is very important. Otherwise, we would
  # have to be very careful and considerate of the workflow status before running
  # this task. Since it is non-destructive, you can run this whenever you want to
  # just make sure things are up to date.
  #
  #   import_file = Import::UminFile.new(:file => "/path/to/file", :parser => UminParser::GeneralEn)
  #   import_file.import_authors
  #   import_file.import_submissions
  #   import_file.link_authors_and_submissions_creating_authorships
  #   import_file.delete_unlinked_authors
  #   import_file.import_rooms
  #   import_file.import_sessions
  #   import_file.link_submissions_and_sessions_creating_presentations
  #
  # There will be cases however where we want batch updates. For example, we might 
  # want to batch update presentation numbers. In these cases, we should create a
  # separate method that does only this. Even so, I think it would be better to
  # use an interactive shell so that we can confirm each update.
  #
  # === Diff
  #
  # You can do a diff comparing versions of a UminFile. We recommend that before
  # doing a batch import, compare the differences by running the diff rake task which
  # delegates to Import::UminFile#diff.
  #
  # The reason for doing this is that due to the non-destructiveness limitation,
  # some changes may not be reflected in the database; the batch import methods
  # may decide to leave the data as is because it might overwrite a manual edit.
  # As a rule of thumb, the batch methods will not change information that is
  # already in the database. Hence the submissions in the diff report that 
  # say <tt>"* Change in submission number [submission number]"</tt> are unlikely
  # to be set to the database. In these cases, we need to manually change the 
  # data from the web-interface. The diff report will tell you what to change.
  #
  # === Workflow
  #
  # See the documementation for the Import module.
  # 
  # === Rake tasks
  #
  # Look into the rake file <tt>import.rake</tt> 
  class UminFile
    def initialize(options)
      @file = options[:file]
      @parser_class = options[:parser].constantize
      @conference = Conference.find_by_tag!(options[:conference_tag])
    end

    # Import Authors from the UMIN file
    #
    # There will be cases where we will end up with Authors without
    # any Authorships. For example, we might have changed an Authors name
    # and run a subsequent Import. Otherwise, a new author might
    # have been added in a Umin file, but since that submission already
    # had some Authorships assigned, we didn't generate Authorships automatically
    # and Author didn't get assigned.
    #
    # In these cases, the new, modified version will end up in the unassigned
    # Authors. We can check these with #diff.
    #
    # Although we don't need to be too concerned with this, I think it's a good
    # idea in general to not let cruft accumulate because it can cause 
    # unexpected behaviour. We should remove them in the #delete_unlinked_authors
    # method.
    #
    # As long as we keep this in mind, #import_authors is non-destructive, meaning
    # that it won't tread upon any Nayose that we did manually. It is safe
    # to put it into a rake dependency.
    def import_authors
      Author.transaction do
        authors_each do |author, submission_number|
          # Authors validate presence of at least on submission.
          # For the author import phase, we simply add the submission
          # we found when we first created the author.
          # Nayose will be done when we import_authorships
          submission = Submission.in_conference(@conference).
                         find_by_submission_number(submission_number)

          # Create new objects
          a = Author.nayose_find_or_create(author, @conference){|a|
                       a.submissions = [submission]
                     }
          output_error_unless_persisted(a)
          if a.en_name.blank? && !author[:en_name].blank?
            a.update_attributes!(:en_name => author[:en_name], :en_name_clean => author[:en_name_clean])
          end
          if a.jp_name.blank? && !author[:jp_name].blank?
            a.update_attributes!(:jp_name => author[:jp_name], :jp_name_clean => author[:jp_name_clean])
          end
        end
      end
    end

    def check_author_cleansing
      authors_each do |author, submission_number|
        puts "#{author[:en_name]} -> #{author[:en_name_clean]}"
        puts "#{author[:jp_name]} -> #{author[:jp_name_clean]}"
        puts "-----------------"
      end
    end

    # Check that the columns in *args
    # are unique for the CSV file
    def check_uniqueness_of *args      
      store = Hash.new
      umin_rows_each do |ur|
        args.each do |arg|
          value = ur.send(arg)
          if !value.blank?
            store[arg] ||= Hash.new
            if store[arg][value]
              puts "NON-UNIQUE: :#{arg} has repeated value of #{value}."
            else
              store[arg][value] = true
            end
          end
        end
      end
    end

    # Import Submissions from the UMIN file
    #
    # This is non-destructive. If a Submission has already been created (as detected by submission_number,
    # we will not overwrite it.
    #
    # Changing pre-existing submissions in batch will be done with more fine-grained methods like
    # #update_submission_disclose_at.
    def import_submissions
      Submission.transaction do
        umin_rows_each do |ur|
          # No depending object
          # Create new objects
          s = Submission.find_or_create_by_submission_number_and_conference_tag(
             ur.submission_number, 
             @conference.database_tag,
             :disclose_at => ur.disclose_at,
             :submission_number => ur.submission_number,
             :en_title => ur.title_en,
             :jp_title => ur.title_jp,
             :jp_abstract => ur.jp_abstract,
             :en_abstract => ur.en_abstract,
             :institutions => ur.institutions.map{|i| Institution.new(:en_name => i[:en_name],
                                                                      :jp_name => i[:jp_name])},
             :keywords => ur.keywords) {|submission|
            submission.conference_tag = @conference.database_tag
          }
          output_error_unless_persisted(s)
        end
      end
    end

    # Import Authorships from the UMIN file
    #
    # This import can cause problems with any prior Nayose so we must be careful. 
    #
    # We will never renew the Authorship assignments if a Submission already
    # has at least one author assigned. This is because we might have overridden
    # automatic Nayose with manual Nayose.
    #
    # In this is the case, then automatic Nayose will screw the Authorships.
    # For example, we might have split the Authors because there were two authors
    # with the same name. If we do an automatic Nayose after that, it might
    # modify the assignment with the wrong author.
    #
    # There might be legitimate cases where the authors data might have
    # changed. We should list these up separately in a rake task for example.
    # One thing we could do is to regenerate a string of Authors from the Authorships
    # and compare that to the stuff in the Umin File.
    #
    # If we *do* want to reload the Authorships from the UMIN file, then we 
    # should simply delete all associated Authorships.
    def link_authors_and_submissions_creating_authorships
      Submission.transaction do
        umin_rows_each do |ur|
          # Find depending objects
          submission_obj = Submission.find_by_submission_number(ur.submission_number)
          raise "No submission in DB for submission_number: #{ur.submission_number}" unless submission_obj
          # TODO:
          # Since we now create authorships on Author object creation,
          # we can't use the authorships count to determine if we
          # should overwrite or not.
          # Instead, we will count the affiliations on each author
          # and update if it is zero.
          #
          # next if submission_obj.authorships.size > 0
          ur.authors.each.with_index do |author, position|
            # Find depending objects
            author_obj = Author.nayose_find({:en_name => author[:en_name], 
                                             :jp_name => author[:jp_name]},
                                            @conference)
            raise "No author in DB for en_name: #{author[:en_name].inspect}, jp_name: #{author[:jp_name].inspect}" unless author_obj
            # Create new objects
            as = Authorship.in_conference(@conference).find_or_create_by_author_id_and_submission_id(author_obj.id, submission_obj.id)
            # If the Authorships have been updated after initial creation
            # during Author creation.
            next if as.affiliations.size > 0
            as.update_attributes!(:position => position,
                                  :is_presenting_author => author[:is_presenting_author],
                                  :en_name => author[:en_name],
                                  :jp_name => author[:jp_name],
                                  :affiliations => author[:affiliations])
            output_error_unless_persisted(as)
          end
        end
      end
    end

    # Destroy Authors that do not have any Authorships.
    # Unlinked Authors are not really Authors anymore ("author" implies that they have at least one Authorship)
    # so we should delete them.
    def delete_unlinked_authors
      unlinked_author_ids = Author.select('authors.id, count(authorships.id) as authorships_count').
                                  joins("LEFT OUTER JOIN authorships ON authorships.author_id = authors.id").
                                  group("authors.id").having("authorships_count = 0").map{|a| a.id}
      Authorship.transaction do
        Author.where(:id => unlinked_author_ids).each do |unlinked_author|
          unlinked_author.destroy
        end
      end
    end

    # Import Rooms from the UMIN file
    #
    # This is non-destructive. If a Room has already been created (as detected by en_name,
    # we will not overwrite it.
    #
    # Changing pre-existing session in batch should be done with more fine-grained methods/
    def import_rooms
      Room.transaction do
        umin_rows_each do |ur|
          # No depending object
          # Create new objects
          room_obj = Room.in_conference(@conference).find_or_create_by_en_name(
                       ur.session_room_en_name,
                       :jp_name => ur.session_room_jp_name,
                       :jp_location => ur.session_room_jp_location,
                       :en_location => ur.session_room_en_location){|r|
            r.conference_tag = @conference.database_tag
          }
          output_error_unless_persisted(room_obj)
        end
      end
    end

    # Import Sessions from the UMIN file
    #
    # This is non-destructive. If a Sessions has already been created (as detected by session_number,
    # we will not overwrite it.
    #
    # Changing pre-existing session in batch should be done with more fine-grained methods/
    def import_sessions
      Session.transaction do
        umin_rows_each do |ur|
          # Find depending objects
          room_obj = Room.in_conference(@conference).find_by_en_name(ur.session_room_en_name)
          raise "No room in DB for en_name: #{ur.session_room_en_name}" unless room_obj
          # Create new objects
          session_obj = Session.in_conference(@conference).find_or_create_by_number(
                           ur.session_number,
                           :starts_at => ur.session_starts_at,
                           :ends_at => ur.session_ends_at,
                           :room_id => room_obj.id,
                           :en_title => ur.session_en_title,
                           :jp_title => ur.session_jp_title,
                           :organizers_string_en => ur.organizers_string_en,
                           :organizers_string_jp => ur.organizers_string_jp) {|s|
            s.type = ur.session_type.to_s
            s.conference_tag = @conference.database_tag
          }
          output_error_unless_persisted(session_obj)
        end
      end
    end

    # Import Presentations from the UMIN file
    #
    # This is non-destructive. If a Presentation has already been created (as detected by session_id and submission_id),
    # we will not overwrite it.
    #
    # Changing pre-existing session in batch should be done with more fine-grained methods.
    def link_submissions_and_sessions_creating_presentations
      Presentation.transaction do
        umin_rows_each do |ur|
          # Find depending objects
          submission_obj = Submission.find_by_submission_number(ur.submission_number)
          session_obj = Session.find_by_number(ur.session_number)
          raise "No submission in DB for submission_number: #{ur.submission_number}" unless submission_obj
          raise "No session in DB for submission_number: #{ur.session_number}" unless session_obj
          # Create new objects
          presentation_obj = Presentation.in_conference(@conference).
                               find_or_create_by_session_id_and_submission_id(session_obj.id, submission_obj.id,
                                                                             :starts_at => ur.starts_at,
                                                                             :number => ur.number_string) {|p|
                                                                               p.type = ur.presentation_type.to_s
                                                                             }
          output_error_unless_persisted(presentation_obj)
        end
      end
    end

    def diff(args)
      raise "must specify OTHER file" unless args[:other]
      parser = args[:parser] ? args[:parser].constantize : @parser_class
      other = UminFile.new(:file => args[:other], :parser => @parser_class)
      result = []

      current_umin_rows = umin_rows_all
      other_umin_rows = other.umin_rows_all
      combined_submission_numbers = current_umin_rows.keys.to_set + other_umin_rows.keys.to_set

      combined_submission_numbers.each do |sn|
        if current_umin_rows.has_key?(sn) && other_umin_rows.has_key?(sn)
          result += compare_row(current_umin_rows[sn], other_umin_rows[sn])
        else
          if current_umin_rows.has_key?(sn)
            result << "* Submission number #{sn} has been deleted in Other"
          else
            result << "* Submission number #{sn} has been added in Other"
          end
        end
      end
      result
    end

    def compare_row(current_umin_row, other_umin_row)
      result = []
      diffs = compare_values(current_umin_row, other_umin_row)
      if !diffs.empty?
        result << "-------"
        result << "* Change in submission number #{current_umin_row.submission_number}"
        result += diffs
      end
      result
    end

    def compare_values(current_umin_row, other_umin_row)
      result = []
      Import::ParserInterface.interface_methods.each do |vtc|
        current_value = current_umin_row.send(vtc)
        other_value = other_umin_row.send(vtc)
        if current_value != other_value
          result << "on [:#{vtc}]\n  current: #{current_value}\n    other: #{other_value}\n"
        end
      end
      result
    end

    # Yields Author information in a block
    # The parser will typically return Author information
    # as a hash with :en_name, :jp_name, :affiliations(as an array of integers)
    #
    #   authors_each do |author|
    #     do_something_with_author
    #   end
    def authors_each
      umin_rows_each do |ur|
        ur.authors.each do |author|
          next if author[:jp_name].blank? && author[:en_name].blank?
          yield author, ur.submission_number
        end
      end
    end

    # Opens the umin_file and returns each row as
    # a UminRow object wrapperd in a RowWrapper object.
    def umin_rows_each
      umin_file_lines_each do |line|
        umin_row = @parser_class.parse(line)
        next unless umin_row.is_valid_submission?
        yield RowWrapper.new(umin_row)
      end
    end

    # Opens the umin_file and returns a hash of
    # all the rows with the submission_numbers as
    # the keys.
    def umin_rows_all
      result = {}
      umin_rows_each {|ur| result[ur.submission_number] = ur}
      result
    end

    private

    def output_error_unless_persisted(obj)
      unless obj.persisted?
        puts "Failed to save #{obj.class} due to #{obj.errors.full_messages}"
        puts obj.inspect
        puts "---------"
      end
    end

    # Opens the file and returns each CSV line as a string.
    #
    # We prefer to yield strings instead of CSV rows
    # because our parser handle CSV rows as-is.
    #
    # However, we need to use CSV.foreach instead of File.gets
    # because line-breaks may occur inside a field.
    #
    # Therefore, we convert the CSV rows from CSV.foreach
    # back into strings.
    def umin_file_lines_each # :doc:
      puts "Reading from #{@file}" unless Rails.env == 'test'
      CSV.foreach(@file) do |row|
        yield row.to_csv
      end
    end
  end
end