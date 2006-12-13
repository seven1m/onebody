class VersesController < ApplicationController
  def index
    @verses = Verse.find :all, :order => '(select count(*) from people_verses where verse_id = verses.id) desc', :select => '*, (select count(*) from people_verses where verse_id = verses.id) as people_count'
    biggest = Tag.find_by_sql("select count(tag_id) as num from tags_verses group by tag_id order by count(tag_id) desc limit 1").first.num.to_i rescue 0
    # to get a range of point sizes between 8pt and 16pt,
    # figure a factor to multiply by the count
    # 1..11 + 9 (10..20)
    @factor = biggest / 11
    @factor = 1 if @factor.zero?
    @tags = Tag.find :all, :order => 'name'
  end
  
  def view
    if params[:id] =~ /^\d+$/
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
