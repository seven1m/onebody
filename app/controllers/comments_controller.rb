class CommentsController < ApplicationController
  def edit
    @verse = Verse.find params[:verse_id]
    @verse.comments.create :person => @logged_in, :text => params[:text]
    flash[:notice] = 'Comment saved.'
    redirect_to :controller => 'verses', :action => 'view', :id => @verse
  end
  
  def delete
    comment = Comment.find params[:id]
    verse = comment.verse
    if comment.admin? @logged_in
      comment.destroy
      flash[:notice] = 'Comment deleted.'
    end
    redirect_to :controller => 'verses', :action => 'view', :id => verse
   end
end
