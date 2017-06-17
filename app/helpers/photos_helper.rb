module PhotosHelper
  def photo_upload_for(object, &block)
    return unless object
    url = object.persisted? ? url_for([object, :photo]) : nil
    id = object.persisted? ? "#{object.class.name.underscore}#{object.id}" : nil
    content_tag(:div, class: 'photo-drop-area') do
      (block_given? ? capture(&block) : '') +
        render(
          partial: 'photos/upload',
          locals: {
            url: url,
            object_id: id,
            html_field_name: "#{object.class.name.underscore}[photo]",
            field_name: 'photo',
            delete: object.photo.exists?
          }
        )
    end
  end

  def picture_upload(album = nil)
    render partial: 'photos/upload',
           locals: {
             url: album ? album_pictures_path(album) : pictures_path,
             object_id: "album#{album.try(:id)}",
             html_field_name: 'pictures[]',
             field_name: 'pictures[]',
             delete: false,
             multiple: true,
             verb: 'POST'
           }
  end
end
