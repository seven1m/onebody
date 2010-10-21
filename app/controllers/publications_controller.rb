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

  def new
    if @logged_in.admin?(:manage_publications)
      @publication = Publication.new
      @groups = Group.all(:conditions => "name like 'Publications%'")
    else
      render :text => t('only_admins'), :layout => true, :status => 401
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
          flash[:notice] = t('publications.saved')
          if params[:send_update_to_group_id].to_i > 0
            @group = Group.find(params[:send_update_to_group_id])
            flash[:message] = Message.new(:subject => t('publications.new_publication_available'), :body => t('publications.inform_publication_available') + ".\n\n#{url_for :controller => 'publications'}", :person => @logged_in, :group => @group, :dont_send => true)
            redirect_to new_message_path(:group_id => @group.id)
          else
            redirect_to publications_path
          end
        else
          render :action => 'new'
        end
      else
        @publication.errors.add(:base, t('publications.you_must_select_file'))
        render :action => 'new'
      end
    else
      render :text => t('only_admins'), :layout => true, :status => 401
    end
  end

  def destroy
    if @logged_in.admin?(:manage_publications)
      Publication.find(params[:id]).destroy
      flash[:notice] = t('publications.deleted')
      redirect_to publications_path
    else
      render :text => t('only_admins'), :layout => true, :status => 401
    end
  end
end
