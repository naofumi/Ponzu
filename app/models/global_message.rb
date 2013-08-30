class GlobalMessage < ActiveRecord::Base
  attr_accessible :en_text, :jp_text
  locale_selective_reader :text, :ja => :jp_text, :en => :en_text  
  belongs_to :conference, :inverse_of => :global_messages

  ## Methods to confirm that the current conference 
  ## is valid.
  scope :in_conference, lambda {|conference|
    where(:conference_id => conference)
  }

  include ConferenceConfirm

end
