module SearchHelper

  def next_page_path(collection, type)
    to_page = collection.current_page + 1
    search_index_path(request.query_parameters.merge(:page => to_page, :type => type))
  end

  def previous_page_path(collection, type)
    to_page = collection.current_page - 1
    if to_page == 1
      to_page = nil
      type = nil 
    end
    search_index_path(request.query_parameters.merge(:page => to_page, :type => type))
  end

  def next_page_params(collection)
    to_page = collection.current_page + 1
    request.query_parameters.merge(:page => to_page)
  end

  def previous_page_params(collection)
    to_page = collection.current_page - 1
    if to_page == 1
      to_page = nil
      type = nil 
    end
    request.query_parameters.merge(:page => to_page)
  end

end

# http://localhost:5000/ja#!_/ja/search?button=&query=直&type=users&utf8=✓
# http://localhost:5000/ja#!_/ja/search?button=&query=直&utf8=✓
