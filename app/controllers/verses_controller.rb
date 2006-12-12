class VersesController < ApplicationController
  def index
    @verses = Verse.find :all, :order => '(select count(*) from people_verses where verse_id = verses.id) desc', :select => '*, (select count(*) from people_verses where verse_id = verses.id) as people_count'
  end
  
  def view
    if params[:id].to_i > 0
      @verse = Verse.find params[:id]
    else
      @verse = Verse.find_by_reference params[:id]
    end
  end
  
  def add_tags
    @verse = Verse.find params[:id]
    @verse.tag_string = params[:tag_string]
    redirect_to :action => 'view', :id => @verse.reference
  end
  
  def delete_tag
    @verse = Verse.find params[:id]
    @verse.tags.delete Tag.find(params[:tag_id])
    redirect_to params[:return_to] or {:action => 'view', :id => @verse.reference}
  end
end
