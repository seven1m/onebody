class CommentsController < ApplicationController
  def create
    comment = Comment.new(comment_params)

    if @logged_in.can_read?(comment.commentable)
      if comment.save
        flash[:notice] = t('comments.saved')
      else
        flash[:error] = comment.errors.values.join('. ')
      end
      redirect_back
    else
      render html: t('comments.object_not_found', name: comment.commentable.class.name), layout: true, status: 404
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    if @logged_in.can_update?(@comment)
      @comment.destroy
      flash[:notice] = t('comments.deleted')
      redirect_back
    else
      render html: t('comments.not_authorized'), layout: true, status: 401
    end
  end

  def comment_params
    params[:comment][:person_id] = @logged_in.id
    params.require(:comment).permit(:text, :commentable_id, :commentable_type, :person_id)
  end
end
