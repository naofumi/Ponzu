class AddIconsToConference < ActiveRecord::Migration
  def change
  	add_column	:conferences, :icons, :text
  end
end
