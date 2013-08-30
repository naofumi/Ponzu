class CreateConferences < ActiveRecord::Migration
  def change
    create_table :conferences do |t|
    	t.string :name
      t.string :module_name
      t.string :tag
      t.string :subdomain
      t.text :dates
      t.string :support_email

      t.timestamps
    end
  end
end
