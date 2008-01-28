class PublicationsController < ApplicationController
  def index
    @publications = Publication.find :all, :order => 'created_at desc'
    @group = Group.find_by_name('Publications')
  end
  
  def edit
    raise 'You must be an administrator to access this feature.' unless @logged_in.admin?(:manage_publications)
    if params[:id]
      @publication = Publication.find params[:id]
    else
      @publication = Publication.new
    end
    if request.post?
      file = params[:publication].delete(:file)
      if @publication.update_attributes params[:publication]
        @publication.file = file
        flash[:notice] = 'Publication saved.'
        if params[:send_update]
          @group = Group.find_by_name('Publications')
          flash[:message] = Message.new(:subject => 'New Publication Available', :body => "This is to inform you that a new publication has been added to #{Setting.get(:name, :site)}.\n\n#{url_for :controller => 'publications'}", :person => @logged_in, :group => @group, :dont_send => true)
          redirect_to :controller => 'messages', :action => 'edit', :group_id => @group.id
        else
          redirect_to :action => 'index'
        end
      else
        flash[:notice] = @publication.errors.full_messages.join('; ')
      end
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
    raise 'You must be an administrator to access this feature.' unless @logged_in.admin?(:manage_publications)
    if request.post?
      Publication.find(params[:id]).destroy
      flash[:notice] = 'Publication deleted.'
    end
    redirect_to :action => 'index'
  end
end
