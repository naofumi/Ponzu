class AddRegistrationConfirmedAtToUsers < ActiveRecord::Migration
  def change
    add_column  :users, :registration_confirmed_at, :timestamp
  end
end
