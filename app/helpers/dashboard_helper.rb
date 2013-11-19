# encoding: utf-8
module DashboardHelper
  def selected_if_menu(menu_string)
    menu_string.to_s == @menu.to_s ? 'selected' : nil
  end

  def ios_button title, path, bg_class, style = ""
    if galapagos?
      content_tag :div,
       (galapagos_bullet +
        link_to(title, path)).html_safe
    else
      link_to path do
        (content_tag(:div, :class => "ios_icon #{bg_class}",
                     :style => style) {
           content_tag(:div, "", :class => "gloss")
         } + 
         content_tag(:p, title)).html_safe
      end
    end
  end

  def multientry_galapagos_button(title, named_path, dates, param_name = nil)
    result = galapagos_bullet + title + ": "
    result += content_tag(:span) do
      dates.map {|date|
        if param_name
          link_to date.strftime('%m/%d'), send(named_path, param_name => to_date_string(date))
        else
          link_to date.strftime('%m/%d'), send(named_path, to_date_string(date))
        end
      }.join(', ').html_safe
    end
    content_tag(:div, result.html_safe)
  end

  # Return the HTML for the grid button of +type+
  def grid_button(type)
    gb = grid_buttons[type] || raise("Grid button of type #{type} is not specified.")
    if grid_buttons[type].respond_to?(:call)
      grid_buttons[type].call
    else
      ios_button gb[:text] || t("dashboard.grid_button_titles.#{gb[:class] || type}").html_safe, 
                 gb[:href].respond_to?(:call) ? gb[:href].call : gb[:href],
                 gb[:class] || type, gb[:style]
    end
  end

  # Define the buttons that we want to put on the icon grid.
  # Button titles should preferrably be set in the localization file,
  # although this can be overridden.
  # 
  # Because some of these buttons need to be dynamically drawn,
  # the value may be a Proc or lambda (something that responds to #call).
  def grid_buttons
    {
      welcome: {
        href: ksp(:docs_path, "#{conference_tag}/welcome")
      },
      welcome_external: {
        href: t('external_urls.welcome').html_safe,
        class: 'welcome'
      },
      announcements: {
        href: ksp(:global_messages_path),
      },
      announcements_external: {
        href: t('external_urls.announcements').html_safe,
        class: 'announcements'
      },
      search: {
        href: ksp(:search_index_path)
      },
      project: {
        href: ksp(:docs_path, "#{conference_tag}/project")
      },
      floor_plan: {
        href: t('external_urls.map').html_safe,
      },
      oral_sessions: lambda {
        ios_button t("dashboard.grid_button_titles.oral_sessions"), 
                   ksp(:timetable_path, 
                       to_date_string(current_conference.closest_date_for('time_table',Time.zone.now))),
                   :oral_sessions
      },
      oral_sessions_list: lambda {
        if galapagos?
          multientry_galapagos_button(t("dashboard.grid_button_titles.oral_sessions_list"), 
                                      :list_timetable_path, 
                                      current_conference.dates_for('time_table'))
        else
          ios_button t("dashboard.grid_button_titles.oral_sessions_list"), 
                     ksp(:list_timetable_path, 
                         to_date_string(current_conference.closest_date_for('time_table',Time.zone.now))),
                     :oral_sessions_list
        end
      },
      poster_sessions: lambda {
        ios_button t("dashboard.grid_button_titles.poster_sessions"), 
                   ksp(:poster_session_path, 
                       to_date_string(current_conference.closest_date_for('presentation/poster', Time.zone.now))),
                   :poster_sessions
      },
      poster_sessions_list: lambda {
        if galapagos?
          multientry_galapagos_button(t("dashboard.grid_button_titles.poster_sessions_list"), 
                                      :list_poster_session_path, 
                                      current_conference.dates_for('presentation/poster'))
        else
          ios_button t("dashboard.grid_button_titles.poster_sessions_list"), 
                     ksp(:list_poster_session_path, 
                         to_date_string(current_conference.closest_date_for('presentation/poster', Time.zone.now))),
                     :poster_sessions_list
        end
      },
      exhibition: lambda {
        if galapagos?
          multientry_galapagos_button(t("dashboard.grid_button_titles.exhibition"), 
                                      :list_booth_session_path, 
                                      current_conference.dates_for('timetable'))
        else
          ios_button t("dashboard.grid_button_titles.exhibition"), 
                   ksp(:booth_session_path, 
                         to_date_string(current_conference.closest_date_for('time_table', Time.zone.now))),
                     :exhibition
        end
      },
      yoruzemi: lambda {
        if galapagos?
          multientry_galapagos_button(t("dashboard.grid_button_titles.yoruzemi"), 
                                      :meet_ups_path, 
                                      current_conference.dates_for('meet_up'), 
                                      :date)
        else
          ios_button t("dashboard.grid_button_titles.yoruzemi"), 
                     ksp(:meet_ups_path, :date => 
                         to_date_string(current_conference.closest_date_for('meet_up',Time.zone.now))),
                     :yoruzemi
        end
      },
      my_presentations: {
        href: ksp(:my_presentations_path)
      },
      my_likes: lambda {
        if galapagos?
          multientry_galapagos_button(t("dashboard.grid_button_titles.my_likes"), 
                                      :my_like_path, 
                                      current_conference.dates_for('time_table'))
        else
          ios_button t("dashboard.grid_button_titles.my_likes"), 
                     ksp(:my_like_path, 
                         to_date_string(current_conference.closest_date_for('time_table', Time.zone.now))),
                     :my_likes
        end
      },
      my_schedule: lambda {
        if galapagos?
          multientry_galapagos_button(t("dashboard.grid_button_titles.my_schedule"), 
                                      :my_schedule_like_path, 
                                      current_conference.dates_for('time_table'))
        else
          ios_button t("dashboard.grid_button_titles.my_schedule"), 
                     ksp(:my_schedule_like_path, 
                         to_date_string(current_conference.closest_date_for('time_table', Time.zone.now))),
                     :my_schedule
        end
      },
      my_votes: {
        href: ksp(:my_votes_likes_path)
      },
      private_messages: {
        href: ksp(:threads_private_messages_path)
      },
      instructions_for_presentations: {
        href: ksp(:docs_path, "#{conference_tag}/speaker_instructions")
      },
      venue_info: {
        href: "http://www.kunibikimesse.jp/14.html"
      },
      access: {
        href: "http://www.kunibikimesse.jp/60.html"
      },
      child_care: {
        href: ksp(:docs_path, "#{conference_tag}/child_care")
      },
      settings: {
        href: lambda {current_user ? ksp(:settings_user_path, current_user) : "Javascript:alert('Must login to access user settings')"}
      },
      download: {
        href: "Javascript:KSSqlCache.initialize();KSCache.simpleBatchLoad('/docs/batch');"
      },
      clear_cache: {
        href: "Javascript:KSSqlCache.clear();localStorage.clear();sessionStorage.clear();alert('Cache cleared');location.reload();"
      },
      switch_language: {
        href: "Javascript:LocaleManager.toggle();location.reload();"
      },
      login: lambda {
        if current_user
          ios_button t("dashboard.grid_button_titles.logout"), 
                     logout_path,
                     :logout
        else
          ios_button t("dashboard.grid_button_titles.login"), 
                     login_path,
                     :login
        end
      },
      likes_report: {
        href: ksp(:likes_report_likes_path)
      },
      votes_report: {
        href: ksp(:votes_report_likes_path)
      },
      conference_home: {
        href: current_conference.conference_home_page_url
      },
      pdf: {
        href: ksp(:docs_path,"#{conference_tag}/pdfs")
      },
      pdf_with_abstract: {
        href: download_full_pdf_sessions_path,
        class: 'pdf'
      }


    }
  end

end
