json.cache! ['v1', current_conference, I18n.locale, 
             @session, params[:bns],
             can?(:edit, Session), params[:page]] do
  json.renderer do
    json.template "templates/dot/show_sessions"
    json.expiry (@expiry || Kamishibai::Cache::DEFAULT_EXPIRY)
  end
  json.id @session.id
  json.number @session.number
  json.title sanitize(@session.title)
  json.show_text @session.show_text
  json.text sanitize(@session.text)
  json.head_title strip_tags(@session.title)
  json.poster_timetable_path @session.path(controller)
  json.starts_at l(@session.starts_at, :format => :month_day_time)
  json.ends_at (@session.starts_at.beginning_of_day == @session.ends_at.beginning_of_day ? 
                @session.ends_at.strftime("%H:%M") : 
                l(@session.ends_at, :format => :month_day_time))
  json.organizers @session.organizers
  json.paginator ks_will_paginate(@presentations)
  json.type @session.type && @session.type.parameterize.underscore
  json.can_edit can?(:edit, Session)
  json.room do
    json.id @session.room && @session.room.id
    json.name @session.room && @session.room.name
  end

  json.presentations @presentations.order("presentations.position ASC, presentations.number ASC").map{|p| p.id}
end