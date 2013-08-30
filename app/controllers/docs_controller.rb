class DocsController < ApplicationController
  layout "docs"
  set_kamishibai_expiry [:show] => 24 * 60 * 60
  @@action_sanitize_regex = /[^0-9a-zA-Z_-]/

  # TODO: Think about doing this to make it easy to render markdown
  # http://stackoverflow.com/questions/4163560/how-can-i-automatically-render-partials-using-markdown-in-rails-3/4418389#4418389
  def show
    action = action_string
  	respond_to do |format|
  		format.html{
        if request.xhr?
          render :action => action, :layout => false
        else
          if galapagos?
            render :action => action, :layout => "layouts/galapagos"
          else
            render :action => action
          end
        end
      }
    end
  end

  # for testing post reqeusts
  def create
    action = action_string
    respond_to do |format|
      format.html{
        if request.xhr?
          render :action => action, :layout => false
        else
          render :action => action
        end
      }
    end
  end

  def index
  end

  # Since we contain user specific information in the top page, and we 
  # need to cache that page, we have to think about how we handle login
  # and logouts with the cache_manifest.
  # Refer to the Numbers file cachemanifest_scheme.numbers
  def manifest
    action = [params[:folder], "manifest"].join("/")
    headers['Cache-Control'] = "max-age=0, no-cache, no-store, must-revalidate"
    headers['Pragma'] = "no-cache"
    headers['Expires'] = "Wed, 11 Jan 1984 05:00:00 GMT"
    headers['Content-Type'] = "text/cache-manifest"
    render :action => action, :layout => false
  end


  def batch
    responses = {}
    pages = ["mockup", "mockup2", "ponzu", "showcase", "tests"]

    pages.each do |page|
      path = File.expand_path("#{page}", "#{__FILE__}/../../views/docs/");
      all_html_files = Dir.entries(path).delete_if{|e| e !~ /\.html\./}.map{|e| e.sub(/\.html\..*$/, "")}

      all_html_files.each do |sub_page|
        url = docs_path("#{page}/#{sub_page}")
        body = run_action(:show, {page: page, sub_page: sub_page}, {xhr: true})
        responses[url] = body
      end
    end
    render :json => responses
  end

  # Test to load a huge number of pages
  # Test results:
  # After the JSON response has been received, loading up the
  # database returns immediately because database actions are asynchronous.
  # However, database queries have simply queued up meaning that subsequent
  # requests to the database (and hence all page transitions) simply wait.
  # One way is to make sure that we don't wait on the database while doing
  # page transitions (but the issue is that we want to know the cache) state
  # in order to set timeout.
  # A Load button makes a lot of sense but it has to work with the asynchronous interface.
  def test_batch
    responses = {}
    page = "showcase"
    sub_page = "introduction"
    1.upto(1000) do |i|
      url = docs_path("#{page}/#{sub_page}")
      body = run_action(:show, {page: page, sub_page: sub_page}, {xhr: true})
      responses["#{url}_#{i}"] = body      
    end
    render :json => responses
  end

  private

  def action_string
    [params[:page], params[:sub_page]].map{|s| s.gsub(@@action_sanitize_regex, '_')}.join('/')
  end

end
