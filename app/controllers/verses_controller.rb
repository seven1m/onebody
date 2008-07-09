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

  def create
    @verse = Verse.find(params[:id])
    @verse.people << @logged_in unless @verse.people.include? @logged_in
    redirect_to @verse
  end
  
  def update
    @verse = Verse.find(params[:id])
    @verse.tag_list.remove(params[:remove_tag]) if params[:remove_tag]
    @verse.tag_list.add(*params[:add_tags].split) if params[:add_tags]
    @verse.save
    redirect_to @verse
  end
  
  def destroy
    @verse = Verse.find(params[:id])
    @verse.people.delete @logged_in
    unless @verse.people.count == 0
      redirect_to @verse
    else
      @verse.destroy
      redirect_to verses_path
    end
  end

end
