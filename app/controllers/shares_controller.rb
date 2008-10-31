class SharesController < ApplicationController
  
  def index
    @pictures = Picture.all(nil, :limit => 10, :order => 'pictures.created_at desc',
      :select => 'pictures.*', :joins => 'left join albums on pictures.album_id = albums.id',
      :conditions => 'albums.group_id is null')
    @verses = Verse.all(:limit => 5, :order => 'created_at desc')
    @recipes = Recipe.paginate(:per_page => 5, :order => 'created_at desc', :page => 1)
    @publications = Publication.all(:limit => 2, :order => 'created_at desc')
  end
  
end
