class AddAdCategoryToPresentations < ActiveRecord::Migration
  def change
    add_column  :presentations, :ad_category, :string
    add_column  :sessions, :ad_category, :string
  end
end
