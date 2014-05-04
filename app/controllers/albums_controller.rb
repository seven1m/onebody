class AlbumsController < ApplicationController

  load_and_authorize_parent :group, :person, shallow: true
  load_and_authorize_resource

  def index
    @albums = albums.readable_by(current_user)
    respond_to do |format|
      format.html
      format.js { render text: @albums.to_json }
    end
  end

  def show
    redirect_to album_pictures_path(@album)
  end

  def new
  end

  def create
    if @album.save
      flash[:notice] = t('albums.saved')
      redirect_to @album
    else
      render action: 'new'
    end
  end

  def edit
  end

  def update
    if @album.update_attributes(album_params)
      flash[:notice] = t('Changes_saved')
      redirect_to @album
    else
      render action: 'edit'
    end
  end

  def destroy
    @album.destroy
    redirect_to albums_path
  end

  private

  def album_params
    params.require(:album).permit(:name, :description, :is_public, :remove_owner)
  end

end
