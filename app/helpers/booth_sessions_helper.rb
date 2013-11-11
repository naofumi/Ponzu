module BoothSessionsHelper
  def booth_mapper(conference)
    "BoothMap::#{conference.module_name}".constantize
  end
end
