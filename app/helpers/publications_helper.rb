module PublicationsHelper
  def icon_image(publication)
    case publication.file_content_type
    when 'application/pdf'
      'clean/acrobat.png'
    when 'audio/mp3'
      'clean/music.png'
    else
      'clean/file.png'
    end
  end

end
