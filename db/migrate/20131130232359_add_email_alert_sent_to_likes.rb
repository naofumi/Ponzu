class AddEmailAlertSentToLikes < ActiveRecord::Migration
  def change
    add_column  :likes, :email_alert_sent, :boolean, :default => false
  end
end
