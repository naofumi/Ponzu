class AddConferenceTagToRelevantTables < ActiveRecord::Migration
  def change
    add_column  :conferences, :database_tag, :string
    add_column  :authors, :conference_tag, :string
    add_column  :authorships, :conference_tag, :string
    add_column  :submissions, :conference_tag, :string
    add_column  :presentations, :conference_tag, :string
    add_column  :sessions, :conference_tag, :string
    add_column  :rooms, :conference_tag, :string
    add_column  :comments, :conference_tag, :string
    add_column  :users, :conference_tag, :string
    add_column  :meet_ups, :conference_tag, :string
    add_column  :participations, :conference_tag, :string
    add_column  :meet_up_comments, :conference_tag, :string

    add_column  :global_messages, :conference_tag, :string
    add_column  :likes, :conference_tag, :string
    add_column  :messages, :conference_tag, :string
    add_column  :receipts, :conference_tag, :string
  end
end
