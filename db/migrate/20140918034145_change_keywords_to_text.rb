class ChangeKeywordsToText < ActiveRecord::Migration
  def up
    change_column :submissions, :keywords, :text
  end

  def down
    change_column :submissions, :keywords, :string
  end
end
