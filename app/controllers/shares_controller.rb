class SharesController < ApplicationController
  def index
    @shares = Picture.find(:all, :limit => 15, :order => 'created_at desc') \
      + Verse.find(:all, :limit => 15, :order => 'created_at desc', :select => '*, (select count(*) from people_verses where verse_id = verses.id) as people_count') \
      + Recipe.find(:all, :limit => 15, :order => 'created_at desc') \
      + Event.find(:all, :limit => 15, :order => 'created_at desc') \
      + Comment.find(:all, :limit => 15, :order => 'created_at desc') \
      + NewsItem.find(:all, :limit => 15, :order => 'published desc') \
      + Publication.find(:all, :limit => 15, :order => 'created_at desc')
    @shares = @shares.sort_by(&:created_at).reverse
  end
end
