class AttachmentsController < ApplicationController
  skip_before_filter :authenticate_user, :only => %w(get)
  
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
  
  # only for page attachments
  def get
    @attachment = Attachment.find(params[:id])
    if (@attachment.page and !@attachment.message and @attachment.has_file?) \
      and (@attachment.page.published? or (get_user and @logged_in.admin?(:edit_pages)))
      send_data File.read(@attachment.file_path), :filename => @attachment.name, :type => @attachment.content_type || 'application/octet-stream', :disposition => 'inline'
    else
      render :text => 'This file cannot be found.', :layout => true, :status => 404
    end
  end
  
  def new
    if params[:page_id]
      @page = Page.find(params[:page_id])
      if @logged_in.can_edit?(@page)
        @attachment = Attachment.new(:page_id => @page.id)
      else
        render :text => 'You are not authorized to edit this page.', :layout => true, :status => 401
      end
    else
      render :text => 'Unknown attachment type.', :layout => true, :status => 500
    end
  end
  
  def create
    if params[:attachment][:page_id]
      @page = Page.find(params[:attachment][:page_id])
      if @logged_in.can_edit?(@page)
        Attachment.create_from_file(params[:attachment])
        flash[:notice] = 'Attachment saved.'
        redirect_back
      else
        render :text => 'You are not authorized to edit this page.', :layout => true, :status => 401
      end
    else
      render :text => 'Unknown attachment type.', :layout => true, :status => 500
    end
  end
  
  def destroy
    @attachment = Attachment.find(params[:id])
    if @logged_in.can_edit?(@attachment)
      @attachment.destroy
      flash[:notice] = 'Attachment deleted.'
      redirect_back
    else
      render :text => 'You are not authorized to edit this page.', :layout => true, :status => 401
    end
  end
  
end
