class AddKsCacheVersionToConference < ActiveRecord::Migration
  def change
  	add_column	:conferences, :ks_cache_version, :string
  end
end
