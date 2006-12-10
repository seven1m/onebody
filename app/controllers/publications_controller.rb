class PublicationsController < ApplicationController
  def index
    @publications = Publication.find :all, :order => 'year(created_at) desc, month(created_at) desc, day(created_at) desc, name'
  end
  
  def edit
    raise 'You must be an administrator to access this feature.' unless @logged_in.admin?
    if params[:id]
      @publication = Publication.find params[:id]
    else
      @publication = Publication.new
    end
    if request.post?
      file = params[:publication].delete(:file)
      @publication.update_attributes params[:publication]
      @publication.file = file
      flash[:notice] = 'Publication saved.'
      redirect_to :action => 'index'
    end
  end
  
  def view
    @publication = Publication.find params[:id]
    if @publication.has_file?
      send_file @publication.file_path, :type => @publication.file_content_type, :disposition => 'inline', :filename => @publication.pseudo_file_name
    else
      render :text => 'File not found.', :layout => true
    end
  end
  
  def delete
    raise 'You must be an administrator to access this feature.' unless @logged_in.admin?
    if request.post?
      Publication.find(params[:id]).destroy
      flash[:notice] = 'Publication deleted.'
    end
    redirect_to :action => 'index'
  end
end
