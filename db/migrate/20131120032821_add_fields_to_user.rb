class AddFieldsToUser < ActiveRecord::Migration
  def change
    add_column  :users, :jp_profile, :text
    add_column  :users, :en_profile, :text
    add_column  :users, :email_notifications, :boolean, :default => true
    add_column  :users, :school_search, :boolean
    add_column  :users, :acad_job_search, :boolean
    add_column  :users, :corp_job_search, :boolean
    add_column  :users, :school_avail, :boolean
    add_column  :users, :acad_job_avail, :boolean
    add_column  :users, :corp_job_avail, :boolean
    add_column  :users, :male_partner_search, :boolean
    add_column  :users, :female_partner_search, :boolean
    add_column  :users, :job_available, :boolean
  end
end
