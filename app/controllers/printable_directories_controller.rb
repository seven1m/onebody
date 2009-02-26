class PrintableDirectoriesController < ApplicationController

  before_filter :check_access

  def new
  end
  
  def create
    if session[:directory_pdf_job].nil? or session[:directory_pdf_job] < 1.minute.ago
      system("#{File.expand_path(Rails.root + '/script/runner')} -e #{Rails.env} \"Site.current = Site.find(#{Site.current.id}); Person.find(#{@logged_in.id}).generate_and_email_directory_pdf(#{params[:with_pictures] ? 'true' : 'false'})\" &")
      session[:directory_pdf_job] = Time.now
    else
      render :text => "It seems a directory was already sent to you a little while ago. Please check your email (and your spam folder just in case).", :layout => true, :status => 401
    end
  end
  
  def show
    redirect_to new_printable_directory_path
  end
  
  private
  
    def check_access
      unless @logged_in.full_access?
        render :text => 'You are not allowed to print the directory. Sorry.', :layout => true, :status => 401
        return false
      end
    end

end
