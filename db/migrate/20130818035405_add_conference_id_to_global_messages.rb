class AddConferenceIdToGlobalMessages < ActiveRecord::Migration
  def change
  	add_column	:global_messages, :conference_id, :integer
  end
end
