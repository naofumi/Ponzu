namespace :sunspot do
	desc "Drop and then reindex all solr models that are located in your application's models directory."
  # This task depends on the standard Rails file naming \
  # conventions, in that the file name matches the defined class name. \
  # By default the indexing system works in batches of 50 records, you can \
  # set your own value for this by using the batch_size argument. You can \
  # also optionally define a list of models to separated by a forward slash '/'
  #
  # $ rake sunspot:reindex                # reindex all models
  # $ rake sunspot:reindex[1000]          # reindex in batches of 1000
  # $ rake sunspot:reindex[false]         # reindex without batching
  # $ rake sunspot:reindex[,Post]         # reindex only the Post model
  # $ rake sunspot:reindex[1000,Post]     # reindex only the Post model in
  #                                       # batchs of 1000
  # $ rake sunspot:reindex[,Post+Author]  # reindex Post and Author model
  # $ rake sunspot:reindex[,,true]        # reindex silencing/skipping the boolean prompt
  task :reindex_engines, [:batch_size, :models, :silence] => [:environment] do |t, args|
    args.with_defaults(:silence => false)
    if args[:silence] == false
      puts "*Note: the reindex task will remove your current indexes and start from scratch."
      puts "If you have a large dataset, reindexing can take a very long time, possibly weeks."
      puts "This is not encouraged if you have anywhere near or over 1 million rows."
      puts "Are you sure you want to drop your indexes and completely reindex? (y/n)"
      answer = STDIN.gets.chomp
      return false unless answer.match(/^y/)
    end

    # Retry once or gracefully fail for a 5xx error so we don't break reindexing
    Sunspot.session = Sunspot::SessionProxy::Retry5xxSessionProxy.new(Sunspot.session)

    # Set up general options for reindexing
    reindex_options = { :batch_commit => false }

    case args[:batch_size]
    when 'false'
      reindex_options[:batch_size] = nil
    when /^\d+$/
      reindex_options[:batch_size] = args[:batch_size].to_i if args[:batch_size].to_i > 0
    end

    # Load all the application's models. Models which invoke 'searchable' will register themselves
    # in Sunspot.searchable.
    Dir.glob(Rails.root.join('app/models/**/*.rb')).each { |path| require path }

    # Naofumi Kagami
    # Get a list of all engines so that we can list any
    # models that are included in them.
    Rails::Application::Railties.engines.each do |engine|
    	if File.exists?(engine.root.join('app/models/'))
    		Dir.glob(engine.root.join('app/models/**/*.rb')).each { |path| require path }
    	end
    end

    # By default, reindex all searchable models
    sunspot_models = Sunspot.searchable

    # Choose a specific subset of models, if requested
    if args[:models]
      model_names = args[:models].split('+')
      sunspot_models = model_names.map{ |m| m.constantize }
    end

    # Set up progress_bar to, ah, report progress
    begin
      require 'progress_bar'
      total_documents = sunspot_models.map { | m | m.count }.sum
      reindex_options[:progress_bar] = ProgressBar.new(total_documents)
    rescue LoadError => e
      $stdout.puts "Skipping progress bar: for progress reporting, add gem 'progress_bar' to your Gemfile"
    rescue Exception => e
      $stderr.puts "Error using progress bar: #{e.message}"
    end

    # Finally, invoke the class-level solr_reindex on each model
    sunspot_models.each do |model|
      model.solr_reindex(reindex_options)
    end
  end


end



