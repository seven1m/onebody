class SharesController < ApplicationController
  def index
    @pictures = Picture.find(:all, :limit => 5, :order => 'created_at desc').reverse
    @num_pictures = Picture.count
    @verses = Verse.find(:all, :limit => 5, :order => 'created_at desc', :select => '*, (select count(*) from people_verses where verse_id = verses.id) as people_count').reverse
    @num_verses = Verse.count
    @recipes = Recipe.find(:all, :limit => 5, :order => 'created_at desc').reverse
    @num_recipes = Recipe.count
  end
end
