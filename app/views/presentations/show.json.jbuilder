json.renderer do
  json.template "templates/dot/show_presentation"
  json.expiry (@expiry || Kamishibai::Cache::DEFAULT_EXPIRY)
end
json.abstract sanitize(@presentation.abstract)
json.number @presentation.number
json.other_numbers (@presentation.submission.presentations - [@presentation]).map{|p| p.number}
json.header_title strip_tags(@presentation.title)
json.title sanitize(@presentation.title)
json.id @presentation.id
json.next_id @presentation.next.id if @presentation.next
json.previous_id @presentation.previous.id if @presentation.previous
json.starts_at l(@presentation.starts_at, :format => :month_day_time)
json.cancel @presentation.cancel
json.disclose_abstract @presentation.disclose_abstract
json.same_submission @presentation.presentations_belonging_to_same_submission.map{|p| p.id}
json.same_authors @presentation.presentations_by_same_authors_but_different_submissions.map{|p| p.id}
json.more_like_this @more_like_this.results.map{|p| p.id}
json.can_edit can?(:edit, Presentation)
json.submission_id @presentation.submission_id

json.room do
  room = @presentation.session.room
  json.name room.name
  json.id room.id
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
json.abstract sanitize @presentation.abstract
json.email_link render(:partial => "email_address", :formats => [:html])
json.keywords @presentation.keywords

related_submissions = (@presentation.submission.submissions_by_same_authors - [@presentation.submission]).compact
json.related related_submissions do |rs|
  json.id rs.id
end
json.javascript "cssSet('#{highlight_authors_css(nil, [], @presentation.authors)}');"
