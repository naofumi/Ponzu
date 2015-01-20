# Conference::ConferenceSpecificModules
#
# This helps us to load conference specific modules which 
# will enable us to customize each conference.
#
# Instead of relying on a configuration file, we detect the
# presence or absence of a module.
module Conference::ConferenceSpecificModules
  ### Custom classes for conferences
  def user_class
    @user_class ||= begin
      "User::#{module_name}".constantize
    rescue
      User
    end
  end
end