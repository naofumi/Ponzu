class AddSecretToLikes < ActiveRecord::Migration
  def change
    add_column  :likes, :is_secret, :boolean, :default => false
  end
end
