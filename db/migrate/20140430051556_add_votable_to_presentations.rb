class AddVotableToPresentations < ActiveRecord::Migration
  def change
    add_column  :presentations, :votable, :boolean, :default => false
  end
end
