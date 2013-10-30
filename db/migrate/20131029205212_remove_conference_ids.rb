class RemoveConferenceIds < ActiveRecord::Migration
  def up
    remove_column :rooms, :conference_id
    remove_column :sessions, :conference_id
    remove_column :submissions, :conference_id
    remove_column :users, :conference_id
    remove_column :global_messages, :conference_id
    remove_column :meet_ups, :conference_id
  end

  def down
    add_column  :rooms, :conference_id
    add_column  :sessions, :conference_id
    add_column  :submissions, :conference_id
    add_column  :users, :conference_id
    add_column  :global_messages, :conference_id
    add_column  :meet_ups, :conference_id
  end
end
