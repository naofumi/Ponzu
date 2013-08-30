require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require
require "ponzu"

module Dummy
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.default_locale = :en
    # Configure locale loading to enable nested directories 
    # http://edgeguides.rubyonrails.org/i18n.html#translationsfor-active-recordmodels
    Rails::Application::Railties.engines.map{|e| e.root}.push(Rails.root).each do |engine_root|
      if File.exists?(engine_root.join('config/locales/'))
        config.i18n.load_path += Dir[engine_root.join('config', 'locales', '**', '*.{rb,yml}')]
      end
    end

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    config.active_record.whitelist_attributes = true

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'


    ################################################################
    ######## We want to move all this stuff to the Conference object
    # Use the manifest file (default: no)
    config.use_manifest = false

    ######### Conference configuration ##########
    # Set the modules customized for the current event
    # config.conference_module = 'Jsdb2013'

    # config.conference_module = 'PonzuDemo'
    # # Set the dates for which to show timetables and poster maps and meet ups
    # config.conference_dates = {
    #   :time_table => ['28', '29', '30', '31'].map{|day| "2013-5-#{day}"},
    #   :'presentation/poster' => ['30'].map{|day| "2013-5-#{day}"},
    #   :meet_up => ['27', '28', '29', '30', '31'].map{|day| "2013-5-#{day}"}
    # }

    # config.support_email = "support@castle104.com"

  end
end

