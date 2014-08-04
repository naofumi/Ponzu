# Monkey patch just for logger info
class JbuilderTemplate < Jbuilder  
  def cache!(key=nil, options={}, &block)
    if @context.controller.perform_caching
      if ::Rails.cache.exist?(_cache_key(key)).inspect
        ::Rails.logger.info "Read fragment from JSON"
      end
      value = ::Rails.cache.fetch(_cache_key(key), options) do
        ::Rails.logger.info "Write fragment from JSON"
        _scope { yield self }
      end

      _merge(value)
    else
      yield
    end
  end
end


class PresentationsController < ApplicationController  
  authorize_resource
  protect_from_forgery :except => :batch_request_likes
  MAXIMUM_NUMBER_OF_PRESENTATIONS_PER_BATCH = 30

  default_menu :sessions

  set_kamishibai_expiry [:heading, :show, :related, :batch_request_likes] => 24 * 60 * 60,
                        [:social_box, :likes, :comments, :my] => 1

  respond_to :html, :js
  include Kamishibai::ResponderMixin

  # GET /presentations
  # GET /presentations.json
  def index
    @presentations = Presentation.in_conference(current_conference).
                     paginate(:page => params[:page], :per_page => 30)
  end

  def my
    if @author = current_user.author
      @presentations = @author && @author.presentations.in_conference(current_conference)
      @receipts = @author.receipts_from_type(Presentation)
    end
  end

  # GET /presentations/1
  # GET /presentations/1.json
  def show
    @presentation = Presentation.in_conference(current_conference).
                    find(params[:id])
    set_menu(@presentation.is_poster? ? :posters : :sessions)
    restrict_disclosure(@presentation)
    # Move @more_like_this to inside the cache because slow

    if !@presentation.session.ad_category.blank?
      @ads = Presentation::Ad.in_conference(current_conference).
                              where(:ad_category => @presentation.session.ad_category).
                              select{|ad| !ad.title.blank?}
    else
      @ads = []
    end
  end

  def heading
    @presentation = Presentation.in_conference(current_conference).
                    find(params[:id])
  end

  def related
    @presentation = Presentation.in_conference(current_conference).
                    find(params[:id])
    @more_like_this = Sunspot.more_like_this(@presentation, Presentation){
                        with(:conference_tag).equal_to(current_conference.database_tag)
                        fields :en_abstract, :en_title, :jp_abstract, :jp_title
                        minimum_word_length 3
                        boost_by_relevance true
                        paginate :per_page => 10
                        minimum_term_frequency 1
                        maximum_query_terms 100
                      }
  end
  
  # POST /presentations
  # POST /presentations.json
  # Presentations will be created by drag-drop of sessions and presentations.
  def create
    type_name = params[:presentation].delete(:type)
    @presentation = Presentation.new(params[:presentation])
    @presentation.type = type_name.constantize.to_s #constantize will effectively sanitize the :type param
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
    type_name = params[:presentation].delete(:type)
    @presentation = Presentation.in_conference(current_conference).
                                 find(params[:id])
    @presentation.type = type_name.constantize.to_s #constantize will effectively sanitize the :type param
    # set_flash @presentation.update_attributes(params[:presentation]),
    #           :success => "Presentation was successfully updated",
    #           :fail => "Presentation failed to update"

    if @presentation.update_attributes(params[:presentation])
      flash[:notice] = "Presentation was successfully updated"
    else 
      flash[:error] = "Presentation failed to update"
    end

    respond_with @presentation, :success_action => :back
  end

  def edit
    @presentation = Presentation.in_conference(current_conference).
                                 find(params[:id])    
  end

  # DELETE /presentations/1
  # DELETE /presentations/1.json
  # Assume that this will be called from a list
  def destroy
    @presentation = Presentation.in_conference(current_conference).
                                 find(params[:id])
    @session = @presentation.session
    

    set_flash @presentation.destroy,
              :success => "Presentation destroyed",
              :fail => "Failed to destroy presentation"
    # We can't use #respond_with here because the response is a partial.
    respond_to do |format|
      format.html { render :partial => 'list', :locals => {:presentations => @session.presentations}}
    end
  end
  
  def likes
    @presentation = Presentation.in_conference(current_conference).
                                 find(params[:id])
    @likes = @presentation.likes.where(:is_secret => false).includes(:user).order("created_at DESC")

    respond_with @presentation
  end

  def social_box
    if current_user
      @presentation = Presentation.in_conference(current_conference).
                                   find(params[:id])
    else
      render nothing: true
    end
  end
  
  # Only available for PC, not galapagos
  def comments
    @presentation = Presentation.in_conference(current_conference).
                                 find(params[:id])
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
    begin
      Presentation.transaction do
        @presentations.each_with_index do |p, i|
          p.position = i + 1
          p.save!
        end
      end
      flash[:notice] = "Reordering succeeded"
    rescue
      flash[:error] = "Reordering failed"
    end

    respond_to do |format|
      format.html { render :partial => "list", :locals => {:presentations => @presentations}}
    end
  end

  def change_ad_category
    @presentation = Presentation.in_conference(current_conference).find(params[:id])
    verify_ownership(@presentation)
    if @presentation.update_attributes(:ad_category => params[:presentation][:ad_category])
      flash[:notice] = "Category successfully changed"
    else
      flash[:error] = "Error"
    end
    device_selective_render :partial => "single_line_edit", :locals => {:p => @presentation}
    # respond_with @presentation, :location => edit_submission_path(@presentation.submission)
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

  def verify_ownership(presentation)
    return true if can?(:moderate, presentation)
    unless current_user.author &&
           presentation.submission.authors.include?(current_user.author)
      raise CanCan::AccessDenied, "Current user cannot access."
    end
  end

end
