json.cache! ['v2', current_conference, I18n.locale, @presentation, !!current_user, can?(:edit, Presentation)] do
  json.renderer do
    json.template "templates/dot/comments_presentation"
    json.expiry (@expiry || Kamishibai::Cache::DEFAULT_EXPIRY)
  end
  json.user_id current_user.id
  json.presentation_id @presentation.id
  authors = @presentation.authors.compact
  json.comments @presentation.comments.order("rgt DESC") do |comment|
    json.id comment.id
    json.is_author authors.include?(comment.user.author)
    json.depth comment.ancestors.size
    json.created_at l(comment.created_at, :format => :month_day_time)
    json.user_name comment.user.name
    json.user_id comment.user.id
    json.text sanitize(auto_link(comment.text))
  end
end