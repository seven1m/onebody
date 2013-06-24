class PicturesController < ApplicationController

  def index
    @album = Album.find(params[:album_id])
    @pictures = @album.pictures.paginate(order: 'id', page: params[:page])
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
        render text: t('There_was_an_error'), layout: true, status: 500
        return
      end
    end
    @album = (@group ? @group.albums : Album).find_or_create_by_name(
      if params[:album].to_s.any? and params[:album] != t('share.default_album_name')
        params[:album]
      elsif @group
        @group.name
      else
        @logged_in.name
      end
    ) { |a| a.person = @logged_in }
    success = fail = 0
    errors = []
    Array(params[:pictures]).each do |pic|
      picture = @album.pictures.create(
        person: (params[:remove_owner] ? nil : @logged_in),
        photo:  pic
      )
      if picture.errors.any?
        errors += picture.errors.full_messages
      end
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
    flash[:notice] = t('pictures.saved', success: success)
    flash[:notice] += " " + t('pictures.failed', fail: fail) if fail > 0
    flash[:notice] += " " + errors.join('; ') if errors.any?
    redirect_to params[:redirect_to] || @group || album_pictures_path(@album)
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
      render text: t('pictures.cant_edit'), layout: true, status: 401
    end
  end

  def destroy
    @album = Album.find(params[:album_id])
    @picture = Picture.find(params[:id])
    if @logged_in.can_edit?(@picture)
      @picture.destroy
      redirect_to @album
    else
      render text: t('pictures.cant_delete'), layout: true, status: 401
    end
  end

end
