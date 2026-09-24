# frozen_string_literal: true

class Admin::CommentsController < Admin::BaseController
  SORTS = { created_at: 'active_admin_comments.created_at', resource_type: 'active_admin_comments.resource_type' }.freeze

  def index
    scope = Admin::Comment.includes(:author, :resource)
    scope = apply_sort(scope, allowed: SORTS, default: :created_at, default_direction: :desc)
    @pagy, @comments = paginate(scope)
  end

  def create
    resource = find_commentable
    @comment = resource.admin_comments.build(comment_params.merge(author: current_admin))

    if @comment.save
      redirect_back_or_to resource_admin_path(resource), notice: 'Comment added.', status: :see_other
    else
      redirect_back_or_to resource_admin_path(resource), alert: @comment.errors.full_messages.to_sentence, status: :see_other
    end
  end

  def destroy
    comment = Admin::Comment.find(params[:id])
    comment.destroy
    redirect_back_or_to admin_comments_path, notice: 'Comment deleted.', status: :see_other
  end

  private

  def comment_params
    params.require(:admin_comment).permit(:body)
  end

  # Only models that opted into AdminCommentable can be commented on.
  def find_commentable
    type = params.require(:resource_type)
    klass = type.safe_constantize
    raise ActiveRecord::RecordNotFound unless klass.is_a?(Class) && klass < ApplicationRecord && klass.include?(AdminCommentable)

    klass.find(params.require(:resource_id))
  end

  # Show-page path for a commentable record in the new admin, falling back to the comments index.
  def resource_admin_path(resource)
    helpers.admin_resource_path(resource) || admin_comments_path
  end
end
