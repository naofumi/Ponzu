class AddThreadedComments < ActiveRecord::Migration
  def change
    add_column  :comments, :parent_id, :integer
    add_column  :comments, :lft, :integer
    add_column  :comments, :rgt, :integer
    add_column  :comments, :child_count, :integer
    add_column  :comments, :commentable_id, :integer
    add_column  :comments, :commentable_type, :string
    add_column  :comments, :depth, :integer
  end
end
