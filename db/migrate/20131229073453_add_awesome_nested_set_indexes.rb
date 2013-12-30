class AddAwesomeNestedSetIndexes < ActiveRecord::Migration
  def change
    add_index :comments, :rgt
    add_index :comments, :parent_id
    add_index :comments, :lft
    add_index :comments, :depth
  end
end
