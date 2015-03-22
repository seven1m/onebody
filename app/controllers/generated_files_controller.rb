class GeneratedFilesController < ApplicationController
  def show
    @file = @logged_in.generated_files.where(job_id: params[:id]).first
    respond_to do |format|
      format.html do
        if @file
          send_file(@file.file.path, type: @file.file.content_type, filename: @file.file_file_name)
        end
      end
      format.js
    end
  end
end
