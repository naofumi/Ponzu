class AddSubmissionInfoToUsers < ActiveRecord::Migration
  def change
    add_column  :users, :submission_info, :string
  end
end
