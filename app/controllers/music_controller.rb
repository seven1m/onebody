class MusicController < ApplicationController
  def index
    @songs = Song.find :all, :order => 'title'
  end
  
  def edit
    if params[:id]
      @song = Song.find params[:id]
    else
      @song = Song.new :person => @logged_in
    end
    if request.post?
      if params[:search] # do a search
        params[:chart].cleanse :title, :artists, :album
        @products = Song.search params[:album] || params[:artists] || params[:title]
      else
        @song.update_attributes params[:song]
      end
    end
  end
end
