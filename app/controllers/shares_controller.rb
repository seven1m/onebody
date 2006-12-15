class SharesController < ApplicationController
  def index
    @pictures = Picture.find :all, :limit => 5, :order => 'rand()'
    @verses = Verse.find :all, :limit => 5, :order => 'rand()', :select => '*, (select count(*) from people_verses where verse_id = verses.id) as people_count'
    @recipes = Recipe.find :all, :limit => 5, :order => 'rand()'
  end
end
