# http://www.alexreisner.com/code/single-table-inheritance-in-rails
PRELOAD_MODEL_FILES_IN_SUBDIRECTORIES = %w(like presentation session)

if Rails.env.development?
  # load in all files in specified directories
  PRELOAD_MODEL_FILES_IN_SUBDIRECTORIES.each do |sti_directory|
    Rails::Application::Railties.engines.map{|e| e.root}.push(Rails.root).each do |engine_root|
      if File.exists?(engine_root.join("app", "models", sti_directory))
        files_in_directory = Dir.glob(File.join(engine_root, "app", "models", sti_directory, "*.rb"))
        files_in_directory.each do |file|
          require_dependency file
        end
      end
    end
  end
  # load individual files
  [].each do |c|
    require_dependency File.join("app","models","#{c}.rb")
  end
end
