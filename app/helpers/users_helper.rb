module UsersHelper
  def consolidated_links(users, id_method, url_method, join_string = ", ", html_options = {})
    result = []
    users.each do |u|
      if !u.send(id_method).blank?
        result << link_to(u.send(id_method), u.send(url_method), html_options)
      end
    end
    result.join(join_string).html_safe
  end
end
