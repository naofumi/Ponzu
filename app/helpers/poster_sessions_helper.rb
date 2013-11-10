module PosterSessionsHelper
  def grid_manager(conference)
    "PosterGrid::#{conference.module_name}".constantize
  end

  def grid_converter(conference)
    "PosterNumberToGrid::#{conference.module_name}".constantize
  end
end
