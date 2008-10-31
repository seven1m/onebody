class AlbumsController < ApplicationController

  def index
    @albums = Album.find_all_by_group_id(nil, :order => 'created_at desc')
  end

  def show
    @album = Album.find(params[:id])
    redirect_to album_pictures_path(@album)
  end
  
  def new
    if @group = Group.find_by_id(params[:group_id]) and can_add_pictures_to_group?(@group)
      @album = @group.albums.build
    else
      @album = Album.new
    end
  end
  
  def can_add_pictures_to_group?(group)
    group.pictures? and (@logged_in.member_of?(group) or group.admin?(@logged_in))
  end
  
  def create
    @album = Album.new(params[:album])
    if @album.group and !can_add_pictures_to_group?(@album.group)
      @album.errors.add_to_base('Cannot add pictures in this group.')
    end
    if @album.save
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
