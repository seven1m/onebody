class AttachmentsController < ApplicationController
  skip_before_filter :authenticate_user, only: %w(get)

  def show
    @attachment = Attachment.find(params[:id])
    if @logged_in.can_read?(@attachment)
      if @attachment.file.exists?
        data = File.read(@attachment.file.path)
        send_data data, filename: @attachment.name, type: @attachment.content_type || 'application/octet-stream', disposition: 'inline'
      else
        render plain: t('attachments.file_deleted'), layout: true, status: 404
      end
    else
      render plain: t('attachments.not_found'), layout: true, status: 404
    end
  end

  def get
    @attachment = Attachment.find(params[:id])
    if @attachment.file.exists? && !@attachment.message
      data = File.read(@attachment.file.path)
      details = { filename: @attachment.name, type: @attachment.content_type || 'application/octet-stream' }
      if @attachment.group && (get_user && @logged_in.can_read?(@attachment.group))
        send_data data, details.merge(disposition: 'inline')
      else
        render plain: t('attachments.file_not_found'), layout: true, status: 404
      end
    else
      render plain: t('attachments.file_not_found'), layout: true, status: 404
    end
  end
end
