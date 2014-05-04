class GeneratedFilesController < ApplicationController

  def show
    @file = @logged_in.generated_files.find_by_job_id(params[:id])
    @job = Job.find_by_id(params[:id])
    respond_to do |format|
      format.html do
        if @file
          # TODO does this still work?
          send_file(@file.file.path, type: @file.file.content_type, filename: @file.file_file_name)
        end
      end
      format.js
    end
  end

end
