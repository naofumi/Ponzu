class TestsController < ApplicationController
  layout false
  set_kamishibai_expiry [:show] => 1 * 60

  # TODO: Think about doing this to make it easy to render markdown
  # http://stackoverflow.com/questions/4163560/how-can-i-automatically-render-partials-using-markdown-in-rails-3/4418389#4418389
  def show
    action = [params[:page], params[:sub_page]].join('/')
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

  # for testing post reqeusts
  def create
    action = [params[:page], params[:sub_page]].join('/')
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

end
