module PhotosHelper
  def photo_upload_for(object)
    if object.is_a? Family
      url = family_photo_path(object, from: request.fullpath + '#family-picture')
    elsif object.is_a? Person
      url = person_photo_path(object, from: request.fullpath + '#picture')
    elsif object.is_a? Picture
      url = picture_photo_path(object, from: request.fullpath)
    else
      url = photo_path(id: object, type: object.class.name.downcase, from: request.fullpath)
    end
    render partial: 'photos/upload',
      locals: {url: url, name: "#{object.class.name} Photo", delete: object.photo.exists?}
  end
end
