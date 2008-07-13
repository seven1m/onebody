class SharesController < ApplicationController
  
  def index
    @pictures = Picture.all(:limit => 10, :order => 'created_at desc')
    @verses = Verse.all(:limit => 5, :order => 'created_at desc')
    @recipes = Recipe.all(:limit => 5, :order => 'created_at desc')
    @publications = Publication.all(:limit => 2, :order => 'created_at desc')
  end
  
end
