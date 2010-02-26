class AttachmentsController < ApplicationController
  skip_before_filter :authenticate_user, :only => %w(get)
  
  def show
    @attachment = Attachment.find(params[:id])
    if @logged_in.can_see?(@attachment)
      if @attachment.has_file?
        data = File.read(@attachment.file_path)
        if data.respond_to?(:encode)
          data.encode!("iso-8859-1", :undef => :replace, :invalid => :replace)
        end
        send_data data, :filename => @attachment.name, :type => @attachment.content_type || 'application/octet-stream', :disposition => 'inline'
      else
        render :text => I18n.t('attachments.file_deleted'), :layout => true, :status => 404
      end
    else
      render :text => I18n.t('attachments.not_found'), :layout => true, :status => 404
    end
  end
  
  # only for page attachments
  def get
    @attachment = Attachment.find(params[:id])
    if (@attachment.page and !@attachment.message and @attachment.has_file?) \
      and (@attachment.page.published? or (get_user and @logged_in.admin?(:edit_pages)))
      send_data File.read(@attachment.file_path), :filename => @attachment.name, :type => @attachment.content_type || 'application/octet-stream', :disposition => 'inline'
    else
      render :text => I18n.t('attachments.file_not_found'), :layout => true, :status => 404
    end
  end
  
  def new
    if params[:page_id]
      @page = Page.find(params[:page_id])
      if @logged_in.can_edit?(@page)
        @attachment = Attachment.new(:page_id => @page.id)
      else
        render :text => I18n.t('not_authorized'), :layout => true, :status => 401
      end
    else
      render :text => I18n.t('attachments.unknown_type'), :layout => true, :status => 500
    end
  end
  
  def create
    if params[:attachment][:page_id]
      @page = Page.find(params[:attachment][:page_id])
      if @logged_in.can_edit?(@page)
        Attachment.create_from_file(params[:attachment])
        flash[:notice] = I18n.t('attachments.saved')
        redirect_back
      else
        render :text => I18n.t('not_authorized'), :layout => true, :status => 401
      end
    else
      render :text => I18n.t('attachments.unknown_type'), :layout => true, :status => 500
    end
  end
  
  def destroy
    @attachment = Attachment.find(params[:id])
    if @logged_in.can_edit?(@attachment)
      @attachment.destroy
      flash[:notice] = I18n.t('attachments.deleted')
      redirect_back
    else
      render :text => I18n.t('not_authorized'), :layout => true, :status => 401
    end
  end
  
end
