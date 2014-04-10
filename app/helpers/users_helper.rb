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

  def consolidated_info(users, method)
    result = []
    users.each do |u|
      value = u.send(method)
      if !value.blank?
        result << value
      end
    end
    result
  end

  # These should be moved to the model
  def name_is_same(user, author)
    return false unless user && author
    name_is_same = (!user.jp_name.blank? && !author.jp_name.blank? && user.jp_name.downcase == author.jp_name.downcase) ||
                   (!user.en_name.blank? && !author.en_name.blank? && user.en_name.downcase == author.en_name.downcase)

  end

  # Splits an email address domain into tokens.
  # Returns an array of tokens that were found in the Authors #unique_affiliation_combos
  def email_affiliation_match(user, author)
    minimal_token_size = 3
    
    return [] unless user && author
    email_affiliation_match = user.email.sub(/^.+@/, '').split(/[^0-9^a-z^A-Z]/).
                              select{|token| 
                                token.size >= minimal_token_size && 
                                author.unique_affiliation_combos.to_a.join(' ').match(/#{token}/i)}
    puts "#{user.name} #{author.name}"
    puts email_affiliation_match.inspect
    return email_affiliation_match
  end
end
