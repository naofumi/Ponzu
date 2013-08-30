class AddConferenceHomePageUrlToConference < ActiveRecord::Migration
  def change
  	add_column	:conferences, :conference_home_page_url, :string
  end
end
