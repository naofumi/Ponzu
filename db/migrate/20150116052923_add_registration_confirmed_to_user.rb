class AddRegistrationConfirmedToUser < ActiveRecord::Migration
  def change
    add_column  :users, :registration_confirmed, :boolean, :default => false
  end
end
