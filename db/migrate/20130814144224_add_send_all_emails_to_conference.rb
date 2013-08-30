class AddSendAllEmailsToConference < ActiveRecord::Migration
  def change
  	add_column	:conferences, :send_all_emails_to, :string, :default => nil
  end
end
