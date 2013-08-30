# desc "Explaining what the task does"
# task :ponzu do
#   # Task goes here
# end

namespace :ponzu do
	task :reset_social => :environment do

		ActiveRecord::Base.logger = Logger.new(STDOUT)
    raise "CONFERENCE_TAG not set" unless ENV['CONFERENCE_TAG']
    conference = Conference.find_by_tag!(ENV['CONFERENCE_TAG'])

    Conference.transaction do
	    Like.in_conference(conference).find_each do |like|
	    	like.destroy
	    end

	    Comment.in_conference(conference).find_each do |comment|
	    	comment.destroy
	    end

	    MeetUp.in_conference(conference).find_each do |meet_up|
	    	meet_up.destroy
	    	# MeetUpComments should be destroyed via :dependent => :destroy
	    	# Particpations should be destroyed via :dependent => :destroy
	    end

	    # Deleting Messages is hard because the sender is
	    # polymorphic and you can't get the conference object
	    # simply via SQL.
	    # We'll plough through each Message sender 
	    # object type.
	    [Presentation, User, Comment].each do |klass|
	    	klass.send(:in_conference, conference).find_each do |obj|
		    	obj.sent_messages.each do |m|
		    		m.destroy# Receipts should be destroyed via :dependent => :destroy
		    	end
		    end
	    end

	   	unless ENV['COMMIT']
		    raise "Set COMMIT=1 to commit changes"
		  end
	  end
	end
end