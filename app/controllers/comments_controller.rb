# encoding: UTF-8
require 'rails_autolink'

class CommentsController < ApplicationController
  authorize_resource
  respond_to :html, :js
  include Kamishibai::ResponderMixin

  set_kamishibai_expiry [:show] => 60

  # GET /comments
  # GET /comments.json
  def index
    @comments = Comment.in_conference(current_conference).all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /comments/1
  # GET /comments/1.json
  def show
    @comment = Comment.in_conference(current_conference).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /comments/new
  # GET /comments/new.json
  def new
    @comment = Comment.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /comments/1/edit
  def edit
    @comment = Comment.in_conference(current_conference).find(params[:id])
  end

  # POST /comments
  # POST /comments.json
  def create
    @comment = Comment.new(params[:comment])
    @comment.conference_confirm = current_conference

    respond_to do |format|
      if @comment.save
        flash[:notice] = "コメントを作成しました"
        if request.xhr?
          format.html { render :show }          
        else
          format.html { redirect_to @comment.presentation}
        end
      else
        # TODO: We need better error handling on Ajax
        flash[:error] = "コメントが作成できませんでした"
        if request.xhr?
          format.html { render :edit }          
        else
          @presentation = @comment.presentation
          format.html { render "presentations/show.g" }
        end
      end       
    end
  end

  # PUT /comments/1
  # PUT /comments/1.json
  #
  # Currently, only Admin users can update comments
  def update
    @comment = Comment.in_conference(current_conference).find(params[:id])
    @comment.conference_confirm = current_conference

    respond_to do |format|
      if @comment.update_attributes(params[:comment])
        flash[:notice] = "コメントが正しくアップデートされました"
        format.html {render :show}
      else
        flash[:error] = "コメントが正しくアップデートされませんでした"
        format.html {render :edit}
      end       
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.json
  def destroy
    @comment = current_user.comments.
               in_conference(current_conference).find(params[:id])
    @presentation = @comment.presentation
    @comment.destroy

    respond_to do |format|
      format.html{
        if request.xhr?
          render :partial => 'presentations/comments'
        end
      }
    end
  end
end
