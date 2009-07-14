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
    @album = Album.find(params[:album_id])
    success = fail = 0
    (1..10).each do |index|
      if ((pic = params["picture#{index}"]).read rescue '').length > 0
        pic.seek(0)
        picture = @album.pictures.create(:person => (params[:remove_owner] ? nil : @logged_in))
        picture.photo = pic
        if picture.has_photo?
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
    flash[:notice] = "#{success} picture(s) saved"
    flash[:notice] += " (#{fail} not saved due to errors)" if fail > 0
    redirect_to @album
  end
  
  # rotate / cover selection
  def update
    @album = Album.find(params[:album_id])
    @picture = Picture.find(params[:id])
    if @logged_in.can_edit?(@picture)
      if params[:degrees]
        @picture.rotate_photo params[:degrees].to_i
      elsif params[:cover]
        @album.pictures.all.each { |p| p.update_attribute :cover, false }
        @picture.update_attribute :cover, true
      end
      redirect_to [@album, @picture]
    else
      render :text => 'You cannot edit this picture.', :layout => true, :status => 401
    end
  end
  
  def destroy
    @album = Album.find(params[:album_id])
    @picture = Picture.find(params[:id])
    if @logged_in.can_edit?(@picture)
      @picture.destroy
      redirect_to @album
    else
      render :text => 'You cannot delete this picture.', :layout => true, :status => 401
    end
  end
  
end
