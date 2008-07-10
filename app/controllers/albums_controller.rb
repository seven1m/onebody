class AlbumsController < ApplicationController

  def index
    @albums = Album.all(:order => 'created_at desc')
  end

  def show
    @album = Album.find(params[:id])
    redirect_to album_pictures_path(@album)
  end
  
  def new
    @album = Album.new
  end
  
  def create
    @album = Album.create(params[:album])
    unless @album.errors.any?
      flash[:notice] = 'Album saved.'
      redirect_to @album
    else
      render :action => 'new'
    end
  end
  
  def edit
    @album = Album.find(params[:id])
    unless @logged_in.can_edit?(@album)
      render :text => 'You cannot edit this album.', :layout => true, :status => 401
    end
  end
  
  def update
    @album = Album.find(params[:id])
    if @logged_in.can_edit?(@album)
      if @album.update_attributes(params[:album])
        flash[:notice] = 'Changes saved.'
        redirect_to @album
      else
        render :action => 'edit'
      end
    else
      render :text => 'You cannot edit this album.', :layout => true, :status => 401
    end
  end
  
  def destroy
    @album = Album.find(params[:id])
    if @logged_in.can_edit?(@album)
      @album.destroy
      redirect_to albums_path
    else
      render :text => 'You cannot delete this album.', :layout => true, :status => 401
    end
  end
  
end
