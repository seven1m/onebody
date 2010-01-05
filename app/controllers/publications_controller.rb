class PublicationsController < ApplicationController
  
  skip_before_filter :authenticate_user, :only => %w(index)
  before_filter :authenticate_user_with_code_or_session, :only => %w(index)
  
  def index
    @publications = Publication.all(:order => 'created_at desc')
    @groups = Group.all(:conditions => "name like 'Publications%'")
    respond_to do |format|
      format.html
      format.xml { render :layout => false }
    end
  end
  
  def show
    @publication = Publication.find(params[:id])
    if @publication.has_file?
      send_file @publication.file_path, :type => @publication.file_content_type, :disposition => 'inline', :filename => @publication.pseudo_file_name
    else
      render :text => I18n.t('file_not_found'), :layout => true, :status => 404
    end
  end
  
  def new
    if @logged_in.admin?(:manage_publications)
      @publication = Publication.new
      @groups = Group.all(:conditions => "name like 'Publications%'")
    else
      render :text => I18n.t('only_admins'), :layout => true, :status => 401
    end
  end
  
  def create
    if @logged_in.admin?(:manage_publications)
      @publication = Publication.new
      if (file = params[:publication].delete(:file)) and not file.is_a? String
        @publication.attributes = params[:publication]
        @publication.person = @logged_in
        if @publication.save
          @publication.file = file
          flash[:notice] = I18n.t('publications.saved')
          if params[:send_update_to_group_id].to_i > 0
            @group = Group.find(params[:send_update_to_group_id])
            flash[:message] = Message.new(:subject => I18n.t('publications.new_publication_available'), :body => I18n.t('publications.inform_publication_available') + ".\n\n#{url_for :controller => 'publications'}", :person => @logged_in, :group => @group, :dont_send => true)
            redirect_to new_message_path(:group_id => @group.id)
          else
            redirect_to publications_path
          end
        else
          render :action => 'new'
        end
      else
        @publication.errors.add_to_base(I18n.t('publications.you_must_select_file'))
        render :action => 'new'
      end
    else
      render :text => I18n.t('only_admins'), :layout => true, :status => 401
    end
  end
  
  def destroy
    if @logged_in.admin?(:manage_publications)
      Publication.find(params[:id]).destroy
      flash[:notice] = I18n.t('publications.deleted')
      redirect_to publications_path
    else
      render :text => I18n.t('only_admins'), :layout => true, :status => 401
    end
  end
end
