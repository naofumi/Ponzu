module RedcarpetHelper
  def markdown
    Redcarpet::Markdown.new(Redcarpet::Render::HTML,
        :autolink => true, :space_after_headers => true,
        :no_intra_emphasis => true)
  end

  def markdown_render(string)
    markdown.render(string).html_safe
  end
end
