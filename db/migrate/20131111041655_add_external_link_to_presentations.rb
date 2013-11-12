class AddExternalLinkToPresentations < ActiveRecord::Migration
  def change
    add_column  :submissions, :external_link, :string
  end
end
