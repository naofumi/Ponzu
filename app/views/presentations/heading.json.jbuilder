json.renderer do
  json.template "templates/dot/heading_presentation"
  json.expiry (@expiry || Kamishibai::Cache::DEFAULT_EXPIRY)
end
json.number @presentation.number
json.title sanitize(@presentation.title) || ""
json.id @presentation.id
json.starts_at l(@presentation.starts_at, :format => :month_day_time)
json.cancel @presentation.cancel
json.authorships  @presentation.submission.authorships.order(:position).all,
                  :author_id, :is_presenting_author, :affiliations, :name
json.institutions @presentation.submission.institutions do |institution|
  json.name institution.name
end
if @presentation.kind_of? Presentation::Art
  json.art_thumb asset_path("#{current_conference.tag}/art/thumbs/#{@presentation.number}.jpg")
end

json.type @presentation.type && @presentation.type.parameterize.underscore
