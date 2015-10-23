json.cache! ['v3', current_conference, I18n.locale, @presentation.session.force_en_locale,
              "/presentation/heading/", @presentation] do
  json.renderer do
    json.template "templates/dot/heading_presentation"
    json.expiry (@expiry || Kamishibai::Cache::DEFAULT_EXPIRY)
  end
  json.number @presentation.number
  temporarily_force_en_locale(@presentation.session.force_en_locale) do
    json.title sanitize(@presentation.title) || ""
  end
  json.id @presentation.id
  json.starts_at presentation_starts_at_html(@presentation)
  json.cancel @presentation.cancel
  temporarily_force_en_locale(@presentation.session.force_en_locale) do
    json.authorships  @presentation.submission.authorships.order(:position).all,
                      :author_id, :is_presenting_author, :affiliations, :name
    json.institutions @presentation.submission.institutions do |institution|
      json.name institution.name
    end
  end
  if @presentation.kind_of? Presentation::Art
    begin
      json.art_thumb asset_path("#{current_conference.tag}/art/thumbs/#{@presentation.number}.jpg")
    rescue Sprockets::Helpers::RailsHelper::AssetPaths::AssetNotPrecompiledError
      json.art_thumb asset_path("#{current_conference.tag}/art/thumbs/empty.png")
    end
  end

  json.type @presentation.type && @presentation.type.parameterize.underscore
end