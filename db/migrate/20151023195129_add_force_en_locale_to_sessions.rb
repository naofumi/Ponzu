class AddForceEnLocaleToSessions < ActiveRecord::Migration
  def change
    add_column  :sessions, :force_en_locale, :boolean, :default => false
  end
end
