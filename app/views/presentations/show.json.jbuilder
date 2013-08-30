json.renderer do
  json.library "dust"
  json.template "show_presentation"
  json.expiry (@expiry || Kamishibai::Cache::DEFAULT_EXPIRY)
end
json.abstract @presentation.abstract
json.html_title t( 'titles.presentation', 
              :number => @presentation.number, 
              :title => strip_tags(@presentation.title))
json.title @presentation.title
json.id @presentation.id
json.number @presentation.number
json.info starts_at_ends_at_combo(@presentation, :month_day_time)
json.room do
  json.link map_link(@presentation)
end
json.authors  @presentation.submission.authorships.includes(:author).order(:position).all,
              :id, :is_presenting_author, :affiliations, :name
number = 1
json.institutions @presentation.submission.institutions do |institution|
  json.number number
  json.name institution.name
  number += 1
end
json.abstract sanitize @presentation.abstract
json.email_link render(:partial => "email_address", :formats => [:html])
json.keywords @presentation.keywords

related_submissions = (@presentation.submission.submissions_by_same_authors - [@presentation.submission]).compact
json.related related_submissions do |rs|
  rp = rs.presentations.first
  json.id rs.id
  json.number rp.number
  json.info starts_at_ends_at_combo(rp, :month_day_time)
  json.authors rs.authorships.includes(:author).order(:position).all,
    :id, :is_presenting_author, :affiliations, :name
  json.title sanitize(rs.title)
  number = 1
  json.institutions rs.institutions do |institution|
    json.number number
    json.name institution.name
    number += 1
  end
end

json.social_box_placeholder(ks_ajax_placeholder :id => ["presentation", @presentation.id, "social_box"],
                            :data => {:ajax => social_box_presentation_path(@presentation)})