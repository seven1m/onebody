class AttachmentsController < ApplicationController
  
  def show
    @attachment = Attachment.find(params[:id])
    if @logged_in.can_see?(@attachment)
      send_data File.read(@attachment.file_path), :filename => @attachment.name, :type => @attachment.content_type || 'application/octet-stream', :disposition => 'inline'
    else
      render :text => 'You are not authorized to view this attachment.', :layout => true, :status => 404
    end
  end
  
end
