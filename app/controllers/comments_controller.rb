class CommentsController < ApplicationController

  def create
    if params[:verse_id]
      object = Verse.find(params[:verse_id])
    elsif params[:note_id]
      object = Note.find(params[:note_id])
    elsif params[:picture_id]
      object = Picture.find(params[:picture_id])
    else
      raise 'Error.'
    end
    if @logged_in.can_see?(object)
      object.comments.create(person: @logged_in, text: params[:text])
      flash[:notice] = t('comments.saved')
      redirect_back
    else
      render text: t('comments.object_not_found', name: object.class.name), layout: true, status: 404
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    if @logged_in.can_edit?(@comment)
      @comment.destroy
      flash[:notice] = t('comments.deleted')
      redirect_back
    else
      render text: t('comments.not_authorized'), layout: true, status: 401
    end
  end

end
