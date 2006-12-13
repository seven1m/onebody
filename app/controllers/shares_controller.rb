class SharesController < ApplicationController
  def index
    @pictures = Picture.find :all, :limit => 10, :order => 'rand()'
    @verses = Verse.find :all, :limit => 10, :order => 'rand()'
    @recipes = Recipe.find :all, :limit => 10, :order => 'rand()'
  end
end
