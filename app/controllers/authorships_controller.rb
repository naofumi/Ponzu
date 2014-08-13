class AuthorshipsController < ApplicationController
  authorize_resource
  respond_to :html, :js, :json
  include Kamishibai::ResponderMixin
  
  # GET /authorships/new
  # GET /authorships/new.json
  def new
    @authorship = Authorship.new
    if params[:author_id]
      @authorship.author = Author.find(params[:author_id])
    end
    if params[:submission_id]
      @authorship.submission = Submission.find(params[:submission_id])
    end

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /authorships/1/edit
  def edit
    @authorship = Authorship.find(params[:id])
  end

  # POST /authorships
  # POST /authorships.json
  def create
    @authorship = Authorship.new(params[:authorship])
    @authorship.conference_confirm = current_conference

    respond_to do |format|
      if @authorship.save
        flash[:notice] = 'Authorship was successfully created.'
        format.html { js_redirect ksp(@authorship) }
      else
        flash[:error] = "Error in input"
        format.html { render action: "new" }
      end
    end
  end

  def drop_on_submission
    @submission = Submission.in_conference(current_conference).find(params[:authorship][:submission_id])
    if (url = params[:data_transfer]['text/plain']) && url =~ /authors\/(\d+)/
      @author = Author.in_conference(current_conference).find($1)
      @authorship = @submission.authorships.build(:author_id => @author.id)
    end
    if @authorship && @authorship.save
      flash[:notice] = "Authorship was successfully created"
    else
      flash[:error] = "Failed to create Authorship"
    end
    respond_to do |format|
      format.html { 
        render :partial => "authorships/list", :locals => {:authorships => @submission.authorships.order(:position)}
      }
    end
  end

  # PUT /authorships/1
  # PUT /authorships/1.json
  def update
    @authorship = Authorship.in_conference(current_conference).find(params[:id])
    @authorship.conference_confirm = current_conference

    respond_to do |format|
      if @authorship.update_attributes(params[:authorship])
        flash[:notice] = 'Authorship was successfully updated.'
        format.html { render action: "edit" }
        # format.html { redirect_to @authorship, notice: 'Authorship was successfully updated.' }
      else
        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /authorships/1
  # DELETE /authorships/1.json
  def destroy
    @authorship = Authorship.in_conference(current_conference).find(params[:id])
    @authorship.destroy

    respond_with @authorship
  end

  # POST /authorships
  def sort
    unordered_authorships = Authorship.in_conference(current_conference).find(params[:authorship_list])
    @authorships = params[:authorship_list].map{|as_id| 
                     unordered_authorships.detect{|ua| ua.id == as_id.to_i}}
    Authorship.transaction do
      @authorships.each_with_index do |as, i|
        as.position = i + 1 # acts_as_list starts with position 1
        as.save!
      end
    end
    respond_to do |format|
      format.html { render :partial => "list", :locals => {:authorships => @authorships}}
    end
  end
end
