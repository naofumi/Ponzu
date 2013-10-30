class GlobalMessage < ActiveRecord::Base
  attr_accessible :en_text, :jp_text
  locale_selective_reader :text, :ja => :jp_text, :en => :en_text  
  # belongs_to :conference, :inverse_of => :global_messages

  include ConferenceRefer

  # Remove after we transition to conference_tags from conference_ids
  def find_conference
    Conference.find(conference_id)
  end

end
