$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "ponzu/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ponzu"
  s.version     = Ponzu::VERSION
  s.authors     = ["Naofumi Kagami"]
  s.email       = ["naofumi@castle104.com"]
  s.homepage    = "http://www.castle104.com"
  s.summary     = "Ponzu conference information system."
  s.description = "Conference information system with social networking and other new & interesting features."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["BSD-LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.3"

  # For IE support
  # This version loads jquery 1.7.2
  # Newer versions of this gem (i.e. 3.0.4) load
  # jquery 1.10.2 which doesn't work with IE8
  # We fix jquery-rails at 2.0.2
  s.add_dependency "jquery-rails", "2.0.2"

  # There was a problem with the 0.3.11 version
  # so we downgraded it.
  s.add_dependency 'mysql2', '= 0.3.10'

  s.add_dependency 'mechanize'
  s.add_dependency 'will_paginate'
  s.add_dependency 'acts_as_list'
  s.add_dependency 'authlogic'
  s.add_dependency 'cancan'
  s.add_dependency 'awesome_nested_set', '~>2.1.6'

  # For error_message_on and error_messages_for
  # I want to revisit this and see if we are still using it.
  s.add_dependency 'dynamic_form'

  s.add_dependency 'sunspot_rails', "~> 2.0.0"
  s.add_dependency 'sunspot_solr', "~> 2.0.0"
  s.add_development_dependency 'sunspot_test'
  s.add_dependency 'progress_bar' # Not sure why we need this

  s.add_dependency 'cache_digests'
  s.add_dependency 'rails_autolink'

  # To use Jbuilder templates for JSON
  s.add_dependency 'jbuilder', "~> 1.5.2"

  # HttpAcceptLanguage to get locale from browser settings
  s.add_dependency 'http_accept_language'

  # For ePub output where we need to convert entities to UTF8
  # to get epubcheck to pass.
  s.add_dependency 'htmlentities'

  # For markdown within our static pages
  s.add_dependency 'redcarpet'

  s.add_dependency 'haml', "~> 4.0.0"
  s.add_dependency 'haml-rails'

  # Use dot.js as the templating language
  # https://github.com/jamifsud/sprockets-dotjs
  # http://olado.github.io/doT/
  #
  # How to specify git source in gemspec is described below
  # http://yehudakatz.com/2010/12/16/clarifying-the-roles-of-the-gemspec-and-gemfile/
  s.add_dependency 'sprockets-dotjs'

  # Use a json generator other than the standard JSON library.
  # The JSON library has an issue with ActiveSupport::OrderedHashes
  # and always escapes the UTF-8 output
  s.add_dependency 'oj'
  # s.add_dependency 'yajl-ruby'

  # The new version of authlogic (probably 3.4) uses SCrypt instead of SHA512.
  # Hence we need these gems.
  # To transition, we use the #transition_from_crypto_providers method
  # http://www.binarylogic.com/2008/11/23/tutorial-upgrade-passwords-easily-with-authlogic/
  # https://github.com/binarylogic/authlogic/commit/083a95ca59c2610b3071f0ff70c3cb3666e17e86
  s.add_dependency 'bcrypt', '~> 3.1.7'
  s.add_dependency 'scrypt', '~> 1.2.1'

  # Use qunit-rails in testing
  s.add_development_dependency 'qunit-rails'

end
