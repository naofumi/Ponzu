# http://steverandytantra.com/thoughts/use-redcarpet-as-a-markdown-filter-for-haml-in-rails
# https://github.com/haml/haml/issues/646
module Haml::Filters
  remove_filter("Markdown") #remove the existing Markdown filter

  module Markdown
    include Haml::Filters::Base

    def markdown_parser
      Redcarpet::Markdown.new(Redcarpet::Render::HTML,
          :autolink => true, :space_after_headers => true,
          :no_intra_emphasis => true, :strikethrough => true)
    end

    def render(string)
      markdown_parser.render(string).html_safe
    end
  end
end