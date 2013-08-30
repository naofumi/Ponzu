class AddConferenceIdToModels < ActiveRecord::Migration
  def change
  	add_column	:users, :conference_id, :integer, :null => false
  	add_column	:submissions, :conference_id, :integer, :null => false
  	add_column	:sessions, :conference_id, :integer, :null => false
  	add_column	:meet_ups, :conference_id, :integer, :null => false
  	add_column	:rooms, :conference_id, :integer, :null => false
  end
end
