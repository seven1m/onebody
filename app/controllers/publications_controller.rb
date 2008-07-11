class PublicationsController < ApplicationController
  def index
    @publications = Publication.all(:order => 'created_at desc')
    @group = Group.find_by_name('Publications')
  end
  
  def show
    @publication = Publication.find(params[:id])
    if @publication.has_file?
      send_file @publication.file_path, :type => @publication.file_content_type, :disposition => 'inline', :filename => @publication.pseudo_file_name
    else
      render :text => 'File not found.', :layout => true, :status => 404
    end
  end
  
  def new
    if @logged_in.admin?(:manage_publications)
      @publication = Publication.new
    else
      render :text => 'You must be an administrator to access this feature.', :layout => true, :status => 401
    end
  end
  
  def create
    if @logged_in.admin?(:manage_publications)
      @publication = Publication.new
      if (file = params[:publication].delete(:file)) and not file.is_a? String
        @publication.update_attributes(params[:publication])
        unless @publication.errors.any?
          @publication.file = file
          flash[:notice] = 'Publication saved.'
          if params[:send_update]
            @group = Group.find_by_name('Publications')
            flash[:message] = Message.new(:subject => 'New Publication Available', :body => "This is to inform you that a new publication has been added to #{Setting.get(:name, :site)}.\n\n#{url_for :controller => 'publications'}", :person => @logged_in, :group => @group, :dont_send => true)
            redirect_to new_message_path(:group_id => @group.id)
          else
            redirect_to publications_path
          end
        else
          render :action => 'new'
        end
      else
        @publication.errors.add_to_base('You must select a file.')
        render :action => 'new'
      end
    else
      render :text => 'You must be an administrator to access this feature.', :layout => true, :status => 401
    end
  end
  
  def destroy
    if @logged_in.admin?(:manage_publications)
      Publication.find(params[:id]).destroy
      flash[:notice] = 'Publication deleted.'
      redirect_to publications_path
    else
      render :text => 'You must be an administrator to access this feature.', :layout => true, :status => 401
    end
  end
end
