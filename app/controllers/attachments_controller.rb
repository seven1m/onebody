class AttachmentsController < ApplicationController
  skip_before_filter :authenticate_user, only: %w(get)

  load_and_authorize_parent :group, only: :index

  def index
    @attachments = attachments
  end

  def show
    @attachment = Attachment.find(params[:id])
    if @logged_in.can_read?(@attachment)
      if @attachment.file.exists?
        data = File.read(@attachment.file.path)
        send_data data, filename: @attachment.name, type: @attachment.content_type || 'application/octet-stream', disposition: 'inline'
      else
        render text: t('attachments.file_deleted'), layout: true, status: 404
      end
    else
      render text: t('attachments.not_found'), layout: true, status: 404
    end
  end

  def get
    @attachment = Attachment.find(params[:id])
    if @attachment.file.exists? and !@attachment.message
      data = File.read(@attachment.file.path)
      details = {filename: @attachment.name, type: @attachment.content_type || 'application/octet-stream'}
      if @attachment.group and (get_user and @logged_in.can_read?(@attachment.group))
        send_data data, details.merge(disposition: 'inline')
      else
        render text: t('attachments.file_not_found'), layout: true, status: 404
      end
    else
      render text: t('attachments.file_not_found'), layout: true, status: 404
    end
  end

  def new
    @group = Group.find(params[:group_id])
    if @group.admin?(@logged_in)
      @attachment = Attachment.new(group_id: @group.id)
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def create
    @group = Group.find(params[:attachment][:group_id])
    if @group.admin?(@logged_in)
      attachment = Attachment.create_from_file(attachment_params)
      if attachment.valid?
        flash[:notice] = t('attachments.saved')
      else
        add_errors_to_flash(attachment)
      end
      redirect_to group_attachments_path(@group)
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def destroy
    @attachment = Attachment.find(params[:id])
    if @logged_in.can_delete?(@attachment)
      @attachment.destroy
      flash[:notice] = t('attachments.deleted')
      redirect_back
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  private

  def attachment_params
    params.require(:attachment).permit(:group_id, :file)
  end

end
