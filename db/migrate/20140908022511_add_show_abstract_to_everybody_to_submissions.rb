class AddShowAbstractToEverybodyToSubmissions < ActiveRecord::Migration
  def change
    add_column  :submissions, :show_abstract_to_everybody, :boolean, :default => false
  end
end
