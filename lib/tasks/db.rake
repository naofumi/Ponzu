namespace :ponzu_engine do
	namespace :db do
		desc "Load the seed data from db/seeds.rb in Ponzu Engine"
		task :seed => :environment do
			Ponzu::Engine.load_seed
		end
	end
end

namespace :db do
  desc "Dump the whole contents of the current database (MySQL only) to an SQL file"
  task :dump_all => [:environment] do
    require 'fileutils'
    database = ActiveRecord::Base.configurations[Rails.env]['database']
    time_string = Time.zone.now.strftime('%Y-%m-%d_%H_%M')
    FileUtils.mkdir_p "#{Rails.root}/db_backups"
    puts "Enter password for database server"
    puts "mysqldump -u root -p #{database} > #{database}_#{time_string}.sql"
    `mysqldump -u root -p #{database} > #{Rails.root}/db_backups/#{database}_#{time_string}.sql`
  end
end