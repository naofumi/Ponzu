module Conference::ConferenceSpecificModules
  ### Custom classes for conferences
  def user_class
    if config("user_class")
      return config(:user_class).constantize
    else
      return User
    end
  end

end