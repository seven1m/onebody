class GroupsController < ApplicationController
  def index
    # people/1/groups
    if params[:person_id]
      @person = Person.find(params[:person_id])
      respond_to do |format|
        format.js   { render :partial => 'person_groups' }
        format.html { render :partial => 'person_groups', :layout => true }
        if can_export?
          format.xml { render :xml =>  @person.groups.to_xml(:except => %w(site_id)) }
          format.csv { render :text => @person.groups.to_csv(:except => %w(site_id)) }
        end
      end
    # search by name or category
    elsif params[:category] or params[:name]
      conditions = []
      conditions.add_condition ['hidden = ? and approved = ?', false, true] unless @logged_in.admin?(:manage_groups)
      conditions.add_condition ['category = ?', params[:category]] if params[:category]
      conditions.add_condition ['name like ?', '%' + params[:name] + '%'] if params[:name]
      @groups = Group.find(:all, :conditions => conditions, :order => 'name')
      conditions[1] = true # only hidden groups
      @hidden_groups = Group.find(:all, :conditions => conditions, :order => 'name')
      respond_to do |format|
        format.html { render :action => 'search' }
        if can_export?
          format.xml { render :xml =>  @groups.to_xml(:except => %w(site_id)) }
          format.csv { render :text => @groups.to_csv(:except => %w(site_id)) }
        end
      end
    # regular index
    else
      @categories = Group.categories
      if @logged_in.admin?(:manage_groups)
        @unapproved_groups = Group.find_all_by_approved(false)
      else
        @unapproved_groups = Group.find_all_by_creator_id_and_approved(@logged_in.id, false)
      end
      @person = @logged_in
      respond_to do |format|
        format.html
        if can_export?
          @groups = Group.paginate(:order => 'name', :page => params[:page], :per_page => params[:per_page] || 50)
          format.xml { render :xml =>  @groups.to_xml(:except => %w(site_id)) }
          format.csv { render :text => @groups.to_csv(:except => %w(site_id)) }
        end
      end
    end
  end
    
  def show
    @group = Group.find params[:id]
    @messages = @group.messages.find :all, :select => '*, (select count(*) from messages r where r.parent_id=messages.id and r.to_person_id is null) as reply_count, (select count(*) from attachments where message_id=messages.id or message_id in (select id from messages r where r.parent_id=messages.id)) as attachment_count'
    @notes = @group.notes.find_all_by_deleted(false, :order => 'created_at desc', :limit => 10)
    @prayer_requests = @group.prayer_requests.find(:all, :conditions => "answer = '' or answer is null", :order => 'created_at desc')
    @answered_prayer_count = @group.prayer_requests.count('*', :conditions => "answer != '' and answer is not null")
    @attendance_dates = @group.attendance_dates
    unless @group.approved? or @group.admin?(@logged_in)
      render :text => 'This group is pending approval', :layout => true
    end
    unless @logged_in.can_see?(@group)
      render :text => 'Group not found.', :layout => true, :status => 404
    end
  end
  
  def new
    if Site.current.max_groups.nil? or Group.count < Site.current.max_groups
      @group = Group.new(:creator_id => @logged_in.id)
      @categories = Group.categories.keys
    else
      render :text => 'No groups can be created at this time. Sorry.', :layout => true, :status => 500
    end
  end
  
  def create
    raise 'no more groups can be created' unless Site.current.max_groups.nil? or Group.count < Site.current.max_groups
    photo = params[:group].delete(:photo)
    if not @logged_in.admin?(:manage_groups) and (params[:group][:link_code] or params[:group][:members_send] or params[:group][:private])
      raise 'You are not authorized to do that.'
    end
    params[:group].cleanse 'address'
    @group = Group.create(params[:group])
    unless @group.errors.any?
      if @logged_in.admin?(:manage_groups)
        @group.update_attribute(:approved, true)
        flash[:notice] = 'The group has been created.'
      else
        @group.memberships.create(:person => @logged_in, :admin => true)
        flash[:notice] = 'Your group has been created and is pending approval.'
      end
      @group.photo = photo
      redirect_to @group
    else
      @categories = Group.categories.keys
      render :action => 'new'
    end
  end
  
  def edit
    @group ||= Group.find(params[:id])
    if @logged_in.can_edit?(@group)
      @unlinked_ids = @group.unlinked_members.map { |p| p.id }
      @categories = Group.categories.keys
    else
      render :text => 'You are not authorized to edit this group.', :layout => true, :status => 401
    end
  end
  
  def update
    @group = Group.find(params[:id])
    if @logged_in.can_edit?(@group)
      params[:group].delete(:approved) unless @logged_in.admin?(:manage_groups)
      photo = params[:group].delete(:photo)
      if not @logged_in.admin?(:manage_groups) and (params[:group][:link_code] or params[:group][:members_send] or params[:group][:private])
        raise 'You are not authorized to do that.'
      end
      params[:group].cleanse 'address'
      if @group.update_attributes(params[:group])
        flash[:notice] = 'Group settings have been saved.'
        @group.photo = photo if photo and (photo.respond_to?(:read) or photo == 'remove' or photo.class.name == 'ActionController::TestUploadedFile')
        redirect_to @group
      else
        edit; render :action => 'edit'
      end
    else
      render :text => 'You are not authorized to edit this group.', :layout => true, :status => 401
    end
  end
  
  def destroy
    @group = Group.find(params[:id])
    if @logged_in.can_edit?(@group)
      @group.destroy
      flash[:notice] = 'Group deleted.'
      redirect_to groups_path
    else
      render :text => 'You are not authorized to delete this group.', :layout => true, :status => 401
    end
  end
  
  private
  
    def feature_enabled?
      unless Setting.get(:features, :groups) and (Site.current.max_groups.nil? or Site.current.max_groups > 0)
        redirect_to people_path
        false
      end
    end
end
