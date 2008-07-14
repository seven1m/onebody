class AttachmentsController < ApplicationController
  
  def show
    @attachment = Attachment.find(params[:id])
    if @logged_in.can_see?(@attachment)
      if @attachment.has_file?
        send_data File.read(@attachment.file_path), :filename => @attachment.name, :type => @attachment.content_type || 'application/octet-stream', :disposition => 'inline'
      else
        render :text => 'This file has been deleted.', :layout => true, :status => 404
      end
    else
      render :text => 'Attachment not found.', :layout => true, :status => 404
    end
  end
  
end
