class PrintableDirectoriesController < ApplicationController

  before_filter :check_access
  before_filter :check_scheduler, :only => 'new'

  def new
  end
  
  def create
    unless @task = session[:directory_pdf_job]
      @task = ScheduledTask.queue(
        "Printed Directory for #{@logged_in.name} (#{@logged_in.id})",
        "Person.find(#{@logged_in.id}).generate_directory_pdf_to_file('TASK_BASE_FILE_PATH.pdf', #{params[:with_pictures] ? 'true' : 'false'})"
      )
      session[:directory_pdf_job] = @task
    end
  end
  
  def show
  end
  
  def show_old
    if @task = session[:directory_pdf_job]
      session[:directory_pdf_job] = nil
      if @task.has_file?
        send_data File.read(@task.file_path), :disposition => 'inline', :type => 'application/pdf', :filename => 'church_directory.pdf'
        @task.destroy
      else
        flash[:warning] = 'There was an error locating your custom PDF.'
        redirect_to new_printable_directory_path
      end
    else
      redirect_to new_printable_directory_path
    end
  end
  
  private
  
    def check_access
      unless @logged_in.full_access?
        render :text => 'You are not allowed to print the directory. Sorry.', :layout => true, :status => 401
        return false
      end
    end

end
