class VersesController < ApplicationController
  def index
    @verses = Verse.find :all, :order => '(select count(*) from people_verses where verse_id = verses.id) desc', :select => '*, (select count(*) from people_verses where verse_id = verses.id) as people_count'
  end
  
  def view
    @verse = Verse.find_by_reference params[:id]
  end
end
