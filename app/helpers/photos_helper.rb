module PhotosHelper
  def photo_upload_for(object)
    if object.is_a? Family
      url = family_photo_path(object, :from => request.request_uri + '#family-picture')
    elsif object.is_a? Person
      url = person_photo_path(object, :from => request.request_uri + '#picture')
    elsif object.is_a? Picture
      url = picture_photo_path(object, :from => request.request_uri)
    elsif object.is_a? Recipe
      url = recipe_photo_path(object, :from => request.request_uri)
    else
      url = photo_path(:id => object, :type => object.class.name.downcase, :from => request.request_uri)
    end
    render :partial => 'photos/upload',
      :locals => {:url => url, :name => "#{object.class.name} Photo", :delete => object.has_photo?}
  end
end
