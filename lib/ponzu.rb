require "ponzu/engine"

module Ponzu
end

# Unlike Bundler, gemspec does not automatically require the gems for us.
require "jquery-rails"

require 'mysql2'

require 'mechanize'
require 'will_paginate'
require 'acts_as_list'
require 'authlogic'
require 'cancan'
require 'awesome_nested_set'

require 'dynamic_form'

require 'sunspot_rails'
require 'sunspot_solr'
require 'progress_bar'

require 'cache_digests'
require 'rails_autolink'

require 'jbuilder'

require 'http_accept_language'

require 'htmlentities'

require 'redcarpet'

require 'haml'
require 'haml-rails'

require 'sprockets-dotjs'

require 'oj'
# require 'yajl/json_gem'

# My libraries
require 'conference_strings'
require 'locale_reader'
require 'simple_serializer'
require 'kamishibai/responder_mixin'
require 'i18n/backend/namespace'
require 'simple_string_parser'
require 'string_cleanser'