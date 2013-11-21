class AddIndexes < ActiveRecord::Migration
  def change
    add_index :likes, [:user_id, :type]
    add_index :users, :author_id
  end

end
