class PresentationsController < ApplicationController  
  authorize_resource
  protect_from_forgery :except => :batch_request_likes
  MAXIMUM_NUMBER_OF_PRESENTATIONS_PER_BATCH = 30

  default_menu :sessions

  set_kamishibai_expiry [:heading, :show, :related, :batch_request_likes] => 24 * 60 * 60,
                        [:social_box, :likes, :comments, :my] => 60

  respond_to :html, :js
  include Kamishibai::ResponderMixin

  # GET /presentations
  # GET /presentations.json
  def index
    @presentations = Presentation.in_conference(current_conference).
                     paginate(:page => params[:page], :per_page => 30)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def my
    if @author = current_user.author
      @presentations = @author && @author.presentations.in_conference(current_conference)
      @receipts = @author.receipts_from_type(Presentation)
    end

    respond_with @presentations
  end

  # GET /presentations/1
  # GET /presentations/1.json
  def show
    @presentation = Presentation.in_conference(current_conference).
                    find(params[:id])
    set_menu(@presentation.is_poster? ? :posters : :sessions)
    restrict_disclosure(@presentation)

    respond_with @presentation
  end

  def heading
    @presentation = Presentation.in_conference(current_conference).
                    find(params[:id])
    respond_to do |format|
      format.html {
        device_selective_render
      }
    end    
  end

  def related
    @presentation = Presentation.in_conference(current_conference).
                    find(params[:id])
    respond_to do |format|
      format.html {
        if request.xhr?
        else
          if galapagos?
            render_sjis 'related.g'
          else
            render
          end
        end
      }
    end
  end
  
  # GET /presentations/new
  # GET /presentations/new.json
  def new
    @presentation = Presentation.new
    @presentation.session = Session.find(params[:session_id]) if params[:session_id]

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @presentation }
    end
  end

  # GET /presentations/1/edit
  def edit
    @presentation = Presentation.find(params[:id])
  end

  # POST /presentations
  # POST /presentations.json
  # Presentations will be created by drag-drop of sessions and presentations.
  def create
    @presentation = Presentation.new(params[:presentation])
    @session = Session.find(params[:presentation][:session_id])
    @presentation.starts_at = @session.starts_at
    if url = params[:data_transfer]['text/plain']
      @presentation.submission =  if url =~ /submissions\/(\d+)/
                                    Submission.find($1)
                                  elsif url =~ /presentations\/(\d+)/
                                    Presentation.find($1).submission
                                  end
    end

    respond_to do |format|
      if @presentation.save
        flash[:notice] = "Presentation was successfully created"
        format.html { render :partial => 'list', :locals => {:presentations => @session.presentations}}
        # format.html { redirect_to @presentation, notice: 'Presentation was successfully created.' }
        # format.json { render json: @presentation, status: :created, location: @presentation }
      else
        flash[:error] = "Presentation failed to create"
        format.html { render :partial => 'list', :locals => {:presentations => @session.presentations}}
        # format.html { render action: "new" }
        # format.json { render json: @presentation.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /presentations/1
  # PUT /presentations/1.json
  def update
    @presentation = Presentation.in_conference(current_conference).
                                 find(params[:id])

    respond_to do |format|
      if @presentation.update_attributes(params[:presentation])
        flash[:notice] = "Presentation was successfully updated"
        format.html { render :partial => "edit", :locals => {:presentation => @presentation} }
      else
        flash[:error] = "Presentation failed to update"
        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /presentations/1
  # DELETE /presentations/1.json
  # Assume that this will be called from a list
  def destroy
    @presentation = Presentation.in_conference(current_conference).
                                 find(params[:id])
    @session = @presentation.session
    @presentation.destroy

    respond_to do |format|
      format.html { render :partial => 'list', :locals => {:presentations => @session.presentations}}
    end
  end
  
  def likes
    @presentation = Presentation.in_conference(current_conference).
                                 find(params[:id])
    @likes = @presentation.likes.includes(:user).order("created_at DESC")

    respond_with @presentation
  end

  def social_box
    @presentation = Presentation.in_conference(current_conference).
                                 find(params[:id])
    respond_to do |format|
      if request.xhr?
        # format.html {
        #   render :partial => 'presentations/social_box'          
        # }
        format.json {
          render 'presentations/social_box'
        }
      else
        format.html {
          # if request.xhr?
          #   render :partial => 'presentations/social_box'
          # else
            render
          # end
        }
      end
    end
  end
  
  def comments
    @presentation = Presentation.in_conference(current_conference).
                                 find(params[:id])
    respond_to do |format|
      format.html {
        if request.xhr?
          render :partial => 'presentations/comments'
        else
          render
        end
      }
    end
  end

  # We also have Comment#create which galapagos uses. 
  # Should decide which to use.
  def create_comment
    @presentation = Presentation.in_conference(current_conference).
                                 find(params[:id])
    @comment = @presentation.comments.build(params[:comment])

    respond_to do |format|
      if @comment.save
        format.html{
          if request.xhr?
            render :partial => 'presentations/comments'
          end
        }
        # format.html {render :partial => 'presentations/comment', :locals => {:c => @comment}}
      else
        format.js { render :js => "KSApp.notify('Failed to create comment')" }
      end
    end
  end
  
  def toggle_schedule
    @presentation = Presentation.in_conference(current_conference).
                                 find(params[:id])
    current_user && current_user.toggle_schedule(@presentation)
    
    redirect_to :back
  end

  def batch_request_likes
    unless current_user
      render(:json => [])
      return
    end
    @likes = current_user.likes.includes(:presentation)
    exclude_paths = params[:exclude_paths] || []

    respond_to do |format|
      fragments = {}
      if !galapagos?
        @likes.each do |l|
          if p = l.presentation
            responses = json_responses_for_presentation(p, exclude_paths)
            break if responses.nil?
            fragments.merge!(responses)
          end
        end
      end

      format.json { render :json => fragments }
    end
  end

  def sort
    unordered_presentations = Presentation.in_conference(current_conference).
                                           find(params[:presentations_list])
    @presentations = params[:presentations_list].map{|p_id| 
                       unordered_presentations.detect{|up| up.id == p_id.to_i}}
    Presentation.transaction do
      @presentations.each_with_index do |p, i|
        p.position = i
        p.save!
      end
    end
    respond_to do |format|
      format.html { render :partial => "list", :locals => {:presentations => @presentations}}
    end
  end

  private

  # return nil if we exceed MAXIMUM_NUMBER_OF_PRESENTATIONS_PER_BATCH
  def json_responses_for_presentation(p, exclude_paths)
    @counter ||= 0 # We want to restrict the number of presentations
                   # downloaded per go.
    return nil if @counter > MAXIMUM_NUMBER_OF_PRESENTATIONS_PER_BATCH
    fragments = {}
    # We only batch load for the current locale.
    # We are seeing people with hundreds of likes, so this makes sense.
    #
    # Same as PresentationContrller#show
    @presentation = p
    @menu = @presentation.is_poster? ? :posters : :sessions
    restrict_disclosure(@presentation)

    path = presentation_path(@presentation, :locale => locale)
    unless exclude_paths.include?(path)
      fragments[path] = render_to_string("show#{".s" if smartphone?}", :formats => [:html], :layout => false)
    end
    @counter += 1
    fragments
  end

  # We restrict disclosure in the controller so that
  # we can better ensure that an error in the view code
  # won't expose the abstract.
  def restrict_disclosure(presentation)
    if cannot? :view_abstract, Presentation
      def presentation.abstract
        I18n.translate('presentations.not_logged_in')
      end
      def presentation.disclose_abstract
        false
      end
    elsif presentation.disclose_at > Time.now
      def presentation.abstract
        I18n.translate('presentations.pending_disclosure', :date => I18n.localize(disclose_at, :format => :month_day))
      end
      def presentation.disclose_abstract
        false
      end
    else
      def presentation.disclose_abstract
        true
      end
    end
  end

end
