class AddBoothNumToPresentations < ActiveRecord::Migration
  def change
    add_column  :presentations, :booth_num, :string
  end
end
