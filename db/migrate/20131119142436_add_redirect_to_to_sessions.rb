class AddRedirectToToSessions < ActiveRecord::Migration
  def change
    add_column  :sessions, :redirect_to, :string
  end
end
