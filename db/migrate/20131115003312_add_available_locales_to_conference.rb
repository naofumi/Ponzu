class AddAvailableLocalesToConference < ActiveRecord::Migration
  def change
    add_column :conferences, :available_locales, :text
  end
end
