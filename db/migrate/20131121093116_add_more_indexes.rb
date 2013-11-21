class AddMoreIndexes < ActiveRecord::Migration
  def change
    add_index :likes, [:presentation_id, :is_secret, :type]
    add_index :conferences, :subdomain
    add_index :presentations, :submission_id
    add_index :presentations, [:conference_tag, :ad_category, :type]
    add_index :authorships, [:submission_id, :position]
  end

end
