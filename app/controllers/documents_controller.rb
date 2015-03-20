class DocumentsController < ApplicationController
  before_action :find_parent_folder, only: %w(index show new)
  before_action :ensure_admin, except: %w(index show download)
  before_action :persist_prefs, only: %(index)

  def index
    @folders = (@parent_folder.try(:folders) || DocumentFolder.top).order(:name).includes(:groups)
    @folders = DocumentFolderAuthorizer.readable_by(@logged_in, @folders)
    if @logged_in.admin?(:manage_documents)
      @hidden_folder_count = @folders.hidden.count
      @restricted_folder_count = @folders.restricted.count('distinct document_folders.id')
    end
    @folders = @folders.open unless @show_restricted_folders
    @folders = @folders.active unless @show_hidden_folders
    @documents = (@parent_folder.try(:documents) || Document.top).order(:name)
  end

  def show
    @document = Document.find(params[:id])
    fail ActiveRecord::RecordNotFound unless @logged_in.can_read?(@document)
  end

  def new
    if params[:folder]
      @folder = (@parent_folder.try(:folders) || DocumentFolder).new
      render action: 'new_folder'
    else
      @document = (@parent_folder.try(:documents) || Document).new
    end
  end

  def create
    if params[:folder]
      @folder = DocumentFolder.new(folder_params)
      if @folder.save
        redirect_to documents_path(folder_id: @folder), notice: t('documents.create_folder.notice')
      else
        render action: 'new_folder'
      end
    else
      @document = Document.new(document_params)
      if @document.save
        redirect_to document_path(@document), notice: t('documents.create.notice')
      else
        render action: 'new'
      end
    end
  end

  def edit
    if params[:folder]
      @folder = DocumentFolder.find(params[:id])
      render action: 'edit_folder'
    else
      @document = Document.find(params[:id])
    end
  end

  def update
    if params[:folder]
      @folder = DocumentFolder.find(params[:id])
      if @folder.update_attributes(folder_params)
        redirect_to documents_path(folder_id: @folder.folder_id), notice: t('documents.update_folder.notice')
      else
        render action: 'edit_folder'
      end
    else
      @document = Document.find(params[:id])
      if @document.update_attributes(document_params)
        redirect_to documents_path(folder_id: @document.folder_id), notice: t('documents.update.notice')
      else
        render action: 'edit'
      end
    end
  end

  def destroy
    if params[:folder]
      @folder = DocumentFolder.find(params[:id])
      @folder.destroy
      redirect_to documents_path(folder_id: @folder.folder_id), notice: t('documents.delete_folder.notice')
    else
      @document = Document.find(params[:id])
      @document.destroy
      redirect_to documents_path(folder_id: @document.folder_id), notice: t('documents.delete.notice')
    end
  end

  def download
    @document = Document.find(params[:id])
    fail ActiveRecord::RecordNotFound unless @logged_in.can_read?(@document)
    send_file(
      @document.file.path,
      disposition: params[:inline] ? 'inline' : 'attachment',
      filename: @document.file_file_name,
      type: @document.file.content_type
    )
  end

  private

  def find_parent_folder
    return if params[:folder_id].blank?
    @parent_folder = DocumentFolder.find(params[:folder_id])
    return if @logged_in.admin?(:manage_documents)
    fail ActiveRecord::RecordNotFound if @parent_folder && !@logged_in.can_read?(@parent_folder)
  end

  def folder_params
    params.require(:folder).permit(:name, :description, :hidden, :folder_id, group_ids: [])
  end

  def document_params
    params.require(:document).permit(:name, :description, :folder_id, :file)
  end

  def feature_enabled?
    return if Setting.get(:features, :documents)
    redirect_to people_path
    false
  end

  def ensure_admin
    return if @logged_in.admin?(:manage_documents)
    render text: t('not_authorized'), layout: true
    false
  end

  def persist_prefs
    cookies[:restricted_folders] = params[:restricted_folders] if params[:restricted_folders].present?
    @show_restricted_folders = !@logged_in.admin?(:manage_documents) || cookies[:restricted_folders] == 'true'
    cookies[:hidden_folders] = params[:hidden_folders] if params[:hidden_folders].present?
    @show_hidden_folders = cookies[:hidden_folders] == 'true'
  end
end
