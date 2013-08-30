# Collection of methods to retrieve conference specific strings
# Include into application_helper.rb to access appropriate CSS,
# and into any other places where we need conference specific folders and files.
module ConferenceStrings
  def conference_tag
    conference_module.underscore
  end

  def conference_module
    Rails.configuration.conference_module
  end

  module_function :conference_tag, :conference_module
end