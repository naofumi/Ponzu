class StaticController < ApplicationController
  set_kamishibai_expiry [:show] => 24 * 60 * 60

  def show
  	respond_to do |format|
  		format.html{
        if request.xhr?
          render :action => "#{params[:page]}", :layout => false
        else
          if galapagos?
            render_sjis "#{params[:page]}.g.#{I18n.locale}"
          else
            render :action => params[:page]
          end
        end
      }
    end
  end

  def layout
    if galapagos?
      redirect_to dashboard_index_path
    else
      render :action => "layout"
    end
  end
end
