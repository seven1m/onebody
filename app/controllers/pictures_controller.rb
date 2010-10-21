class PicturesController < ApplicationController

  def index
    @album = Album.find(params[:album_id])
    @pictures = @album.pictures.paginate(:order => 'id', :page => params[:page])
  end

  def show
    @album = Album.find(params[:album_id])
    @picture = Picture.find(params[:id])
  end

  def next
    @album = Album.find(params[:album_id])
    ids = @album.picture_ids
    next_id = ids[ids.index(params[:id].to_i)+1] || ids.first
    redirect_to album_picture_path(params[:album_id], next_id)
  end

  def prev
    @album = Album.find(params[:album_id])
    ids = @album.picture_ids
    prev_id = ids[ids.index(params[:id].to_i)-1]
    redirect_to album_picture_path(params[:album_id], prev_id)
  end

  def create
    if params[:group_id]
      unless @group = Group.find(params[:group_id]) and @group.pictures? \
        and (@logged_in.member_of?(@group) or @logged_in.can_edit?(@group))
        render :text => t('There_was_an_error'), :layout => true, :status => 500
        return
      end
    end
    if params[:album_id].to_s =~ /^\d+$/
      @album = (@group ? @group.albums : Album).find(params[:album_id])
    elsif not ['', '!'].include?(params[:album_id].to_s)
      @album = (@group ? @group.albums : @logged_in.albums).find_or_create_by_name(params[:album_id])
    else
      render :text => t('pictures.error_finding'), :layout => true, :status => 500
      return
    end
    success = fail = 0
    (1..10).each do |index|
      if pic = params["picture#{index}"]
        picture = @album.pictures.create(
          :person => (params[:remove_owner] ? nil : @logged_in),
          :photo  => pic
        )
        if picture.photo.exists?
          success += 1
          if @album.pictures.count == 1 # first pic should be default cover pic
            picture.update_attribute(:cover, true)
          end
        else
          fail += 1
          picture.log_item.destroy rescue nil
          picture.destroy rescue nil
        end
      end
    end
    flash[:notice] = t('pictures.saved', :success => success)
    flash[:notice] += " " + t('pictures.failed', :fail => fail) if fail > 0
    redirect_to params[:redirect_to] || @album
  end

  # rotate / cover selection
  def update
    @album = Album.find(params[:album_id])
    @picture = Picture.find(params[:id])
    if @logged_in.can_edit?(@picture)
      if params[:degrees]
        @picture.rotate params[:degrees].to_i
      elsif params[:cover]
        @album.pictures.all.each { |p| p.update_attribute :cover, false }
        @picture.update_attribute :cover, true
      end
      redirect_to [@album, @picture]
    else
      render :text => t('pictures.cant_edit'), :layout => true, :status => 401
    end
  end

  def destroy
    @album = Album.find(params[:album_id])
    @picture = Picture.find(params[:id])
    if @logged_in.can_edit?(@picture)
      @picture.destroy
      redirect_to @album
    else
      render :text => t('pictures.cant_delete'), :layout => true, :status => 401
    end
  end

end
