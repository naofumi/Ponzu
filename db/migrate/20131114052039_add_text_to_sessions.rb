class AddTextToSessions < ActiveRecord::Migration
  def change
    add_column  :sessions, :jp_text, :text
    add_column  :sessions, :en_text, :text
    add_column  :sessions, :show_text, :boolean
  end
end
