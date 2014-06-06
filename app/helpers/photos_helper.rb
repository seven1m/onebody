module PhotosHelper
  def photo_upload_for(object)
    url = object.persisted? ? url_for([object, :photo]) : nil
    id = object.persisted? ? "#{object.class.name.underscore}#{object.id}" : nil
    render partial: 'photos/upload',
      locals: {
        url: url,
        object_id: id,
        field_name: "#{object.class.name.underscore}[photo]",
        name: "#{object.class.name} Photo",
        delete: object.photo.exists?,
        new: object.new_record?
      }
  end
end
