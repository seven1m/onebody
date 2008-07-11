class CommentsController < ApplicationController

  def create
    if params[:verse_id]
      object = Verse.find(params[:verse_id])
    elsif params[:recipe_id]
      object = Recipe.find(params[:recipe_id])
    elsif params[:note_id]
      object = Note.find(params[:note_id])
    else
      raise 'Error.'
    end
    if @logged_in.can_see?(object)
      object.comments.create(:person => @logged_in, :text => params[:text])
      flash[:notice] = 'Comment saved.'
      redirect_back
    else
      render :text => "That #{object.class.name} was not found.", :layout => true, :status => 404
    end
  end
  
  def destroy
    @comment = Comment.find(params[:id])
    if @logged_in.can_edit?(@comment)
      @comment.destroy
      flash[:notice] = 'Comment deleted.'
      redirect_back
    else
      render :text => 'You are not authorized to delete this comment.', :layout => true, :status => 401
    end
  end
   
end
