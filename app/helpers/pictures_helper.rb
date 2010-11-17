module PicturesHelper
  def picture_path(picture)
    album_picture_path(picture.album, picture)
  end
end
