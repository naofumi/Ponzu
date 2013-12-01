json.cache! ['v3', current_conference, I18n.locale, "/presentation/", 
             @presentation, !!current_user, current_user && current_user.roles] do
  @more_like_this = Sunspot.more_like_this(@presentation, Presentation){
                      with(:conference_tag).equal_to(current_conference.database_tag)
                      fields :en_abstract, :en_title, :jp_abstract, :jp_title
                      minimum_word_length 3
                      boost_by_relevance true
                      paginate :per_page => 10
                      minimum_term_frequency 1
                      maximum_query_terms 100
                    }
  json.renderer do
    json.template "templates/dot/show_presentation"
    json.expiry (@expiry || Kamishibai::Cache::DEFAULT_EXPIRY)
  end
  json.abstract (sanitize(@presentation.abstract) || "")
  json.external_link @presentation.submission.external_link
  json.number @presentation.number
  json.other_numbers (@presentation.submission.presentations - [@presentation]).map{|p| p.number}
  json.header_title strip_tags(@presentation.title) || ""
  json.title sanitize(@presentation.title) || ""
  json.id @presentation.id
  json.next_id @presentation.next.id if @presentation.next
  json.previous_id @presentation.previous.id if @presentation.previous
  json.starts_at l(@presentation.starts_at, :format => :month_day_time)
  json.cancel @presentation.cancel
  json.disclose_abstract @presentation.disclose_abstract
  json.same_submission @presentation.presentations_belonging_to_same_submission.map{|p| p.id}
  json.same_authors @presentation.presentations_by_same_authors_but_different_submissions.map{|p| p.id}
  json.more_like_this @more_like_this.results.map{|p| p.id}
  json.ads @ads.map{|ad| ad.id}
  json.can_edit can?(:edit, Submission)
  json.user_id current_user && current_user.id
  json.submission_id @presentation.submission_id
  json.type @presentation.type && @presentation.type.parameterize.underscore
  json.poster_timetable_path @presentation.session.path(controller)
  if @presentation.submission.show_email && current_user
    json.email @presentation.submission.corresponding_email
  end
  if @presentation.kind_of?(Presentation::Oral) && !@presentation.submission.speech_language.blank?
    json.speech_language @presentation.submission.speech_language 
  end

  json.room do
    room = @presentation.session.room
    json.name room && room.name
    json.id room && room.id
  end
  json.session do
    session = @presentation.session
    json.id session.id
    json.number session.number
  end
  json.authorships  @presentation.submission.authorships.order(:position).all,
                    :author_id, :is_presenting_author, :affiliations, :name
  json.institutions @presentation.submission.institutions do |institution|
    json.name institution.name
  end
  json.keywords @presentation.keywords.select{|k| !k.blank?}

  related_submissions = (@presentation.submission.submissions_by_same_authors - [@presentation.submission]).compact
  json.related related_submissions do |rs|
    json.id rs.id
  end

  if @presentation.kind_of? Presentation::Art
    begin
      json.art asset_path("#{current_conference.tag}/art/web/#{@presentation.number}.jpg")
    rescue Sprockets::Helpers::RailsHelper::AssetPaths::AssetNotPrecompiledError
    end
  end

  json.javascript "cssSet('#{highlight_authors_css(nil, [], @presentation.authors)}');"
end