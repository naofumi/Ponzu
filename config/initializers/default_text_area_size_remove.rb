# http://stackoverflow.com/questions/3719869/change-default-rails-text-area-helper-rows-cols
#
# As mentioned in the last answer, these defaults are going away anyway.
class ActionView::Helpers::InstanceTag
  silence_warnings do
    DEFAULT_FIELD_OPTIONS = {}
    DEFAULT_TEXT_AREA_OPTIONS = {}
  end
end