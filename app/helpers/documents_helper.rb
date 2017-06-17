module DocumentsHelper
  def document_icon_class(document)
    case document.try(:file).try(:content_type)
    when /^image/
      'fa fa-file-image-o'
    when 'application/pdf'
      'fa fa-file-pdf-o'
    when 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      'fa fa-file-word-o'
    when 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      'fa fa-file-excel-o'
    when 'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
      'fa fa-file-powerpoint-o'
    when 'video/x-ms-asf', 'video/x-msvideo', 'video/x-flv', 'video/mp4', 'video/quicktime', 'video/x-ms-wmv'
      'fa fa-file-video-o'
    when 'application/x-zip-compressed', 'application/zip'
      'fa fa-file-archive-o'
    else
      'fa fa-file-o'
    end
  end

  def parent_document_folder_options(folder = nil)
    DocumentFolder.where.not(id: folder.try(:id) || 0)
                  .order(:path)
                  .reject { |f| f.parent_folder_ids.include?(folder.try(:id)) }
                  .map { |f| [f.path, f.id] }
  end
end
