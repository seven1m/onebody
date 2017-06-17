module AlbumsHelper
  def album_avatar_path(album, size = :tn)
    if album.try(:cover).try(:photo).try(:exists?)
      album.cover.photo.url(size)
    else
      size = :large unless size == :tn # we only have only two sizes
      image_path("picture.#{size}.jpg")
    end
  end

  def album_avatar_tag(album, options = {})
    options[:class] = "avatar #{options[:size]} #{options[:class]}"
    options.reverse_merge!(size: :tn, alt: album.try(:name))
    options.reverse_merge!(data: { id: "album#{album.id}", size: options[:size] })
    image_tag(album_avatar_path(album, options.delete(:size)), options)
  end

  def show_album_actions
    @logged_in.admin?(:manage_pictures) || @group.try(:admin?, @logged_in)
  end
end
