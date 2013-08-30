# A Class to hold the number of times an Author appeared in a set
# of results. Used as the return value for Authorship.author_frequency_in_authorships
class Author::Appearances
  def initialize
    @author_appearances = {}
  end

  def increment(author)
    @author_appearances[author] ||= 0
    @author_appearances[author] += 1
  end

  def appearances(author)
    @author_appearances[author] || 0
  end

  def authors_more_than_once(options)
    excluded = options[:excluding] || []
    @author_appearances.inject([]) do |memo, key_value|
      author, appearances = key_value
      if appearances > 1 && !excluded.include?(author)
        memo << author
      end
      memo
    end
  end

  def authors_who_appeared_n_times(number)
    @author_appearances.select{|author, appearances| appearances == number}.keys
  end
end
