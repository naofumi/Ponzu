# The dashboard to display updates, etc.
#
# We are currently using an Accordion interface from jQuery UI
# to provide the drill-down interface, but I'm not really sure that
# this is the best approach.
#
# We should try to rethink the interface based on inspiration from
# iOS. Can we use a Miller Column like interface like iOS/iPods?
# 
# The problem with Accordions is that when opened, the push the next
# tab to the bottom, and sometimes out of the fold. We want to make it
# more obvious that there is a hierarchy one level above.
#
# iPads have a Miller column interface that is on the left hand side of
# the screen. It only works with one level of hierary depth, but for the
# dashboard UI, that might be sufficient.
# 
# It would be nice if we could provide AJAX and/or nice transitions.

class DashboardController < ApplicationController
  protect_from_forgery :except => :batch_request_pages
  
  before_filter do |c|
    @menu = :home
    # Time to live (expiry) time for dashboard views.
    # The client will use localStorage cache until expiry.
    # @expiry = 5 * 60 # seconds
  end

  set_kamishibai_expiry [:index] => 24 * 60 * 60, [:notifications] => 10 * 60

  
  # Since we contain user specific information in the top page, and we 
  # need to cache that page, we have to think about how we handle login
  # and logouts with the cache_manifest.
  # Refer to the Numbers file cachemanifest_scheme.numbers
  #
  # TODO: Move this to its own controller
  def cache_manifest
    headers['Cache-Control'] = "max-age=0, no-cache, no-store, must-revalidate"
    headers['Pragma'] = "no-cache"
    headers['Expires'] = "Wed, 11 Jan 1984 05:00:00 GMT"
    headers['Content-Type'] = "text/cache-manifest"
    render :layout => false
  end

  def index
    respond_to do |format|
      format.html {
        device_selective_render
      }
    end
  end

  # Notifications for new messages and stuff.
  #
  # Will also update links to poster_maps and timetables so that
  # they direct to the current date.
  def notifications
    # This is stale
    #
    # respond_to do |format|
    #   format.html {
    #     if galapagos?
    #       render_sjis "notifications.g"
    #     end
    #   }
    # end
  end

  def batch_request_pages
    unless current_user
      render(:json => [])
      return
    end
    exclude_paths = params[:exclude_paths] || []

    respond_to do |format|
      fragments = {}
      if !smartphone? && !galapagos?
        [:liked_presentations_ajax, :scheduled_presentations_ajax].each do |action|
          fragments.merge!(json_responses_for_dashboard_actions(action, exclude_paths))
        end
      end

      format.json { render :json => fragments }
    end
  end

  private

  def json_responses_for_dashboard_actions(action, exclude_paths)
    fragments = {}
    path = url_for(:controller => :dashboard, :action => action, :locale => locale, :only_path => true)
    unless exclude_paths.include?(path)
      fragments[path] = render_to_string("#{action}#{".s" if smartphone?}", :formats => [:html], :layout => false)
    end
    fragments
  end


end
