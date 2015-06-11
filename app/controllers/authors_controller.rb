# encoding: utf-8
class AuthorsController < ApplicationController
  authorize_resource :except => [:show]
  respond_to :html, :js
  include Kamishibai::ResponderMixin

  set_kamishibai_expiry [:show] => 1 * 60 * 60

  before_filter do |c|
    @menu = :home
    # @expiry = 60 * 60 # seconds
  end

  # GET /authors
  # GET /authors.json
  def index
    if params[:query].blank?
      @authors = Author.in_conference(current_conference).
                        paginate(:page => params[:page], :per_page => 30)
    else
      tokens = params[:query].split(/ |　/)
      @authors = Author.in_conference(current_conference).
                        paginate(:page => params[:page], :per_page => 30)
      tokens.each do |t|
        @authors = @authors.where("jp_name LIKE ? OR en_name LIKE ?", "%#{t}%", "%#{t}%")
      end
    end

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /authors/1
  # GET /authors/1.json
  def show
    @author = Author.in_conference(current_conference).
                     find(params[:id])

    respond_to do |format|
      format.html {
        device_selective_render
      }
    end
  end

  # GET /authors/new
  # GET /authors/new.json
  def new
    if params[:initial_authorship]
      @authorship = Authorship.find(params[:initial_authorship])
      @author = Author.new(:en_name => @authorship.en_name,
                           :jp_name => @authorship.jp_name)
    else
      @author = Author.new
    end

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /authors/1/edit
  def edit
    @author = Author.in_conference(current_conference).
                     find(params[:id])
  end

  # POST /authors
  # POST /authors.json
  def create
    @author = Author.new(params[:author])
    @author.conference_confirm = current_conference

    if @author.save
      flash[:notice] = "Author was successfully created"
    else
      authorships_errors = @author.authorships.map{|as| as.errors.full_messages}.join(' ')
      flash[:error] = "Failed to create Author #{@author.errors.full_messages} #{authorships_errors}"
    end
    respond_with @author, :success_action => :back
  end

  # PUT /authors/1
  # PUT /authors/1.json
  def update
    @author = Author.find(params[:id])
    @author.conference_confirm = current_conference

    if @author.update_attributes(params[:author])
      flash[:notice] = 'Author was successfully updated.'
    else
      authorships_errors = @author.authorships.map{|as| as.errors.full_messages}.join(' ')
      flash[:error] = "Failed to update Author #{@author.errors.full_messages} #{authorships_errors}"
    end
    respond_with @author, :success_action => :back
  end

  # DELETE /authors/1
  # DELETE /authors/1.json
  def destroy
    @author = Author.in_conference(current_conference).find(params[:id])
    if @author.destroy
      flash[:notice] = "Author was successfully destroyed."
    else
      flash[:error] = "Failed to destroy Author #{@author.errors.full_messages}"
    end

    respond_with @author, :success_action => :back, :action => :edit
  end

  def replace
    @author = Author.in_conference(current_conference).find(params[:id])
    Authorship.transaction do
      if params[:data_transfer]['text/html'] =~ /authorships\/(\d+)/
        @authorship = Authorship.in_conference(current_conference).find($1)
        @authorship.author = @author
        if @authorship.save
          flash[:notice] = "Authorship was successfully transfered"
        else
          flash[:error] = "Failed to transfer authorship"
        end
      end
    end

    respond_to do |format|
      format.html { render :partial => 'authorships', :object => @author.authorships}
    end
  end
end
