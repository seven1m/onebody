class PrintableDirectoriesController < ApplicationController
  before_filter :check_access

  def new
  end

  def create
    PrintableDirectoryJob.perform_later(
      @logged_in,
      params[:with_pictures].present?
    )
  end

  def show
    redirect_to new_printable_directory_path
  end

  private

  def check_access
    return if @logged_in.full_access?
    render text: t('printable_directories.not_allowed'), layout: true, status: 401
    false
  end
end
