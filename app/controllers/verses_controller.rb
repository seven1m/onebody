class VersesController < ApplicationController

  def index
    @verses = Verse.paginate(
      :order => 'book, chapter, verse',
      :select => '*, (select count(*) from people_verses where verse_id = verses.id) as people_count',
      :page => params[:page]
    )
    @tags = Verse.tag_counts
  end
  
  def show
    @verse = Verse.find(params[:id])
  end
  
  # add/remove tags
  # add/remove people
  def update
    @verse = Verse.find(params[:id])
    @verse.tag_list.remove(params[:remove_tag]) if params[:remove_tag]
    @verse.tag_list.add(*params[:add_tags].split) if params[:add_tags]
    @verse.save
    redirect_to @verse
  end
end
