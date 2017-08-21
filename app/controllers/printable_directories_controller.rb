class PrintableDirectoriesController < ApplicationController
  before_action :check_access

  def index
    redirect_to action: :new
  end

  def new
  end

  def create
    file = @logged_in.generated_files.create
    PrintableDirectoryJob.perform_later(
      Site.current,
      @logged_in.id,
      file.id,
      params[:with_pictures].present?
    )
    redirect_to action: :show, id: file.id
  end

  def show
    @file = @logged_in.generated_files.find(params[:id])
    respond_to do |format|
      format.html do
        if @file.file.present?
          send_file @file.file.path, type: @file.file.content_type, filename: I18n.t('printable_directories.filename')
        end
      end
      format.js
    end
  end

  private

  def check_access
    return if @logged_in.active?
    render plain: t('printable_directories.not_allowed'), layout: true, status: 401
    false
  end
end
