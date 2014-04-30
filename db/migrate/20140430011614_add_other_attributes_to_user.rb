class AddOtherAttributesToUser < ActiveRecord::Migration
  def change
    add_column  :users, :other_attributes, :text
  end
end
