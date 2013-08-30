# encoding: UTF-8

module PresentationsHelper
  # OTHER_HIGHLIGHT_AUTHORS_COLORS = ['color_0', 'color_1', 'color_2', 'color_3', 
  #                                   'color_4', 'color_5', 'color_6', 'color_7',
  #                                   'color_8']
  OTHER_HIGHLIGHT_AUTHORS_COLORS = ['#ffb7b7', '#b7ffff', '#ffdbb7', '#b7dbff', 
                                    '#ffffb7', '#b7b7ff', '#dbffb7', '#dbb7ff',
                                    '#b7ffb7', '#ffb7ff', '#b7ffdb', '#C2C2C2']


  #TODO: Remove the highlight_authors stuff so that we can cache this across views
  #      Instead, add "author_[user_id]" to the class so we can target it with JS.
  #      Javascript can be generated afterwards to highlight each author.
  # We gave up on ERB because it was introducing too many whitespaces.
  def authors_list(submission, highlight_authors = [], 
                    other_highlight_authors = [], with_links = true,
                    with_classes = true, single_language = true)

    buffer = ""
    authorships = submission.authorships.includes(:author).order(:position).all
    last_index = authorships.size - 1
    number_of_instititions = submission.institutions.size

    authorships.each_with_index do |authorship, i|
      a = authorship.author

      if with_classes
        classes = ["author_#{a.id}"]
        # TODO: Instead of adding hightlight authors stuff here, we'll move it out to Javascript
        classes += highlight_related_classes(a, highlight_authors, other_highlight_authors)
        buffer << "<span class='#{classes.join(' ')}'>"
      else
        buffer << "<span>"
      end
      buffer << '○' if authorship.is_presenting_author
      buffer << author_html(authorship, with_links)
      buffer << ',' unless i == last_index
      if number_of_instititions > 1
        buffer << content_tag(:sup, authorship.affiliations.join(', '))
      end
      buffer << ' ' unless i == last_index
      buffer << '</span>'
    end
    buffer.html_safe
  end

  def author_html(authorship, with_links = true)
    if with_links    
      link_to authorship.name, ksp(:author_path, authorship.author)
    else
      authorship.name
    end
  end
  
  def institutions_list(submission, options = {})
    return "" unless submission.institutions
    same_line = options[:same_line] ? true : false
    number_of_institutions = submission.institutions.size
    tag = same_line ? :span : :div
    result = ""

    submission.institutions.each_with_index do |inst, i|
      institution_number = i + 1
      result << content_tag(tag) do
        number_tag = if number_of_institutions > 1
          content_tag(:sup, institution_number)
        end
        
        "#{number_tag}#{inst.name}".html_safe
      end
    end
    result.html_safe
  end
  
  def like_for_current_user_and_presentation(presentation)
    current_user && current_user.likes.detect{|l| l.presentation_id == presentation.id}
  end

  def schedule_for_current_user_and_presentation(presentation)
    current_user && current_user.schedules.detect{|l| l.presentation_id == presentation.id}
  end

  def current_user_likes_this(presentation)
    like_for_current_user_and_presentation(presentation) && true
  end

  def current_user_scheduled_this(presentation)
    schedule_for_current_user_and_presentation(presentation) && true
  end
  
  def keyword_links(presentation)
    presentation.keywords.map{|kw|
                 link_to(sanitize(kw), ksp(search_index_path(:query => kw, :type => :presentations)))
               }.join(', ').html_safe
  end

  def map_link(presentation, options = {})
    presentation.session && link_to(presentation.session.room.name + " (#{t('map')})", 
                                    ksp(presentation.session.room), options)
  end

  private 

  def highlight_related_classes(author, highlight_authors, other_highlight_authors)
    classes = []
    classes << 'highlight' if highlight_authors.include?(author)
    if other_highlight_authors && other_highlight_authors.include?(author)
      classes << 'other_highlight'
      classes <<  'color_' + other_highlight_authors.index(author).modulo(
                    PresentationsHelper::OTHER_HIGHLIGHT_AUTHORS_COLORS.size).to_s
    end
    classes
  end

  def highlight_authors_css(author, highlight_authors = [], other_highlight_authors = [])
    result_hash = Hash.new("")
    colors = PresentationsHelper::OTHER_HIGHLIGHT_AUTHORS_COLORS
    if author
      result_hash[".author_#{author.id} > a"] += "border: solid 1px red;border-radius: 4px;padding: 0 5px;"
    end

    other_highlight_authors.each.with_index do |oha, i|
      result_hash[".author_#{oha.id} > a"] += "border-left:solid 5px #{colors[i.modulo(colors.size)]};padding: 0 0 0 2px;"
      # result_hash[".author_#{oha.id} > a"] += "background-color:#{colors[i.modulo(colors.size)]};border-radius: 8px;padding: 0 5px;"
    end
    result = ""
    result_hash.each do |k, v|
      result << escape_javascript("#{k} {#{v}}\n")
    end
    result
  end

end
