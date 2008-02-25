class CommentsController < ApplicationController
  def edit
    if params[:verse_id]
      object = Verse.find params[:verse_id]
    elsif params[:recipe_id]
      object = Recipe.find params[:recipe_id]
    elsif params[:event_id]
      object = Event.find params[:event_id]
    elsif params[:news_item_id]
      object = NewsItem.find params[:news_item_id]
    elsif params[:song_id]
      unless @logged_in.music_access? or @logged_in.admin?(:manage_music)
        render :text => 'You are not authorized.'
        return
      end
      object = Song.find params[:song_id]
    elsif params[:note_id]
      object = Note.find params[:note_id]
    else
      raise 'Error.'
    end
    object.comments.create :person => @logged_in, :text => params[:text]
    flash[:notice] = 'Comment saved.'
    redirect_to params[:return_to] + '#comments'
  end
  
  def delete
    comment = Comment.find params[:id]
    if comment.admin? @logged_in
      comment.destroy
      flash[:notice] = 'Comment deleted.'
    end
    redirect_to params[:return_to] || '/'
   end
end
