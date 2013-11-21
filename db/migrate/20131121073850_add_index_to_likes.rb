class AddIndexToLikes < ActiveRecord::Migration
  def change
    add_index :likes, [:conference_tag, :presentation_id]
  end
end
