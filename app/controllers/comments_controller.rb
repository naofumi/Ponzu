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
    @comment.user = current_user
    @comment.conference_confirm = current_conference

    respond_to do |format|
      if @comment.save
        flash[:notice] = "コメントを作成しました"
        if request.xhr?
          @presentation = @comment.presentation
          format.json { render 'presentations/comments'}
          # format.html { render :partial => 'presentations/comments' }          
        else
          format.html { redirect_to @comment.presentation}
        end
      else
        # TODO: We need better error handling on Ajax
        flash[:error] = "コメントが作成できませんでした"
        raise @comment.errors.inspect
        if request.xhr?
          format.js { render :js => "KSApp.notify('Failed to create comment')" }
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
    @comment.destroy
    
    if @comment.destroyed?
      flash[:notice] = 'Comment deleted'
    else
      flash[:error] = "Failed to delete comment. #{@comment.errors.full_messages}"
    end

    @presentation = @comment.presentation
    respond_to do |format|
      if request.xhr?
        format.json { render 'presentations/comments'}
      end
    end
  end

  def reply
    parent_comment = Comment.find(params[:id])
    @comment = Comment.new
    @comment.parent_id = parent_comment.id
    @comment.user = current_user

    respond_with @comment
  end
end
