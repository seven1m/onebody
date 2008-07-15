module PicturesHelper
  def picture_path(picture)
    album_picture_path(picture.album, picture)
  end
  
  def small_picture_path(picture)
    small_album_picture_photo_path(picture.album, picture, :m => picture.updated_at.to_s(:number))
  end
  
  def medium_picture_path(picture)
    medium_album_picture_photo_path(picture.album, picture, :m => picture.updated_at.to_s(:number))
  end
  
  def large_picture_path(picture)
    large_album_picture_photo_path(picture.album, picture, :m => picture.updated_at.to_s(:number))
  end
  
  def full_picture_path(picture)
    album_picture_photo_path(picture.album, picture, :m => picture.updated_at.to_s(:number))
  end
  
  def picture_url(picture)
    album_picture_url(picture.album, picture)
  end
  
  def small_picture_url(picture)
    small_album_picture_photo_url(picture.album, picture, :m => picture.updated_at.to_s(:number), :code => params[:code])
  end
  
  def medium_picture_url(picture)
    medium_album_picture_photo_url(picture.album, picture, :m => picture.updated_at.to_s(:number), :code => params[:code])
  end
  
  def large_picture_url(picture)
    large_album_picture_photo_url(picture.album, picture, :m => picture.updated_at.to_s(:number), :code => params[:code])
  end
  
  def full_picture_url(picture)
    album_picture_photo_url(picture.album, picture, :m => picture.updated_at.to_s(:number), :code => params[:code])
  end
end
