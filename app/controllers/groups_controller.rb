class GroupsController < ApplicationController

  def index
    # people/1/groups
    if params[:person_id]
      @person = Person.find(params[:person_id])
      respond_to do |format|
        format.js   { render partial: 'person_groups' }
        format.html { render action: 'index_for_person' }
        if can_export?
          format.xml { render xml:  @person.groups.to_xml(except: %w(site_id)) }
          format.csv { render text: @person.groups.to_csv_mine(except: %w(site_id)) }
        end
      end
    # /groups?category=Small+Groups
    # /groups?name=college
    elsif params[:category] or params[:name]
      @categories = Group.category_names
      conditions = []
      conditions.add_condition ['hidden = ? and approved = ?', false, true] unless @logged_in.admin?(:manage_groups)
      conditions.add_condition ['category = ?', params[:category]] if params[:category]
      conditions.add_condition ['name like ?', '%' + params[:name] + '%'] if params[:name]
      @groups = Group.where(conditions).order('name')
      conditions_for_hidden = conditions.dup
      conditions_for_hidden[1] = true # only hidden groups
      @hidden_groups = Group.where(conditions_for_hidden).order('name')
      respond_to do |format|
        format.html { render action: 'search' }
        format.js
        if can_export?
          format.xml { render xml:  @groups.to_xml(except: %w(site_id)) }
          format.csv { render text: @groups.to_csv_mine(except: %w(site_id)) }
        end
      end
    # /groups
    else
      @categories = Group.category_names
      if @logged_in.admin?(:manage_groups)
        @unapproved_groups = Group.unapproved
      else
        @unapproved_groups = Group.unapproved.where(creator_id: @logged_in.id)
      end
      @person = @logged_in
      respond_to do |format|
        format.html
        if can_export?
          format.xml do
            job = Group.create_to_xml_job
            redirect_to generated_file_path(job.id)
          end
          format.csv do
            job = Group.create_to_csv_job
            redirect_to generated_file_path(job.id)
          end
        end
      end
    end
  end

  def show
    @group = Group.find(params[:id])
    @members = @group.people.minimal unless fragment_exist?(controller: 'groups', action: 'show', id: @group.id, fragment: 'members')
    @member_of = @logged_in.member_of?(@group)
    if @member_of or (not @group.private? and not @group.hidden?) or @group.admin?(@logged_in)
      @stream_items = @group.shared_stream_items(20)
    else
      @stream_items = []
    end
    @show_map = Setting.get(:services, :yahoo) && @group.mapable?
    @show_cal = @group.gcal_url
    @can_post = @group.can_post?(@logged_in)
    @can_share = @group.can_share?(@logged_in)
    @albums = @group.albums.order('name')
    unless @group.approved? or @group.admin?(@logged_in)
      render text: t('groups.this_group_is_pending_approval'), layout: true
      return
    end
    unless @logged_in.can_see?(@group)
      render text: t('groups.not_found'), layout: true, status: 404
      return
    end
  end

  def new
    if Group.can_create?
      @group = Group.new(creator_id: @logged_in.id)
      @categories = Group.categories.keys
    else
      render text: t('groups.no_more'), layout: true, status: 401
    end
  end

  def create
    if Group.can_create?
      photo = params[:group].delete(:photo)
      params[:group].cleanse 'address'
      @group = Group.new(group_params)
      @group.creator = @logged_in
      @group.photo = photo
      if @group.save
        if @logged_in.admin?(:manage_groups)
          @group.update_attribute(:approved, true)
          flash[:notice] = t('groups.created')
        else
          @group.memberships.create(person: @logged_in, admin: true)
          flash[:notice] = t('groups.created_pending_approval')
        end
        redirect_to @group
      else
        @categories = Group.categories.keys
        render action: 'new'
      end
    else
      render text: t('groups.no_more'), layout: true, status: 401
    end
  end

  def edit
    @group ||= Group.find(params[:id])
    if @logged_in.can_edit?(@group)
      @categories = Group.categories.keys
      @members = @group.people.minimal.order('last_name, first_name')
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def update
    @group = Group.find(params[:id])
    if @logged_in.can_edit?(@group)
      params[:group][:photo] = nil if params[:group][:photo] == 'remove'
      params[:group].cleanse 'address'
      if @group.update_attributes(group_params)
        flash[:notice] = t('groups.settings_saved')
        redirect_to @group
      else
        edit; render action: 'edit'
      end
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def destroy
    @group = Group.find(params[:id])
    if @logged_in.can_edit?(@group)
      @group.destroy
      flash[:notice] = t('groups.deleted')
      redirect_to groups_path
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  def batch
    if @logged_in.admin?(:manage_groups)
      if request.post?
        @errors = []
        @groups = Group.order('category, name')
        @groups.group_by(&:id).each do |id, groups|
          group = groups.first
          if vals = params[:groups][id.to_s]
            unless group.update_attributes(vals.permit(*group_attributes))
              @errors << [id, group.errors.full_messages]
            end
          end
        end
      else
        @groups = Group.order('category, name')
      end
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  private

  def group_attributes
    base = [:name, :description, :photo, :meets, :location, :directions, :other_notes, :address, :members_send, :private, :category, :leader_id, :blog, :email, :prayer, :attendance, :gcal_private_link, :approval_required_to_join, :pictures, :cm_api_list_id]
    base += [:approved, :link_code, :parents_of, :hidden] if @logged_in.admin?(:manage_groups)
    base
  end

  def group_params
    params.require(:group).permit(*group_attributes)
  end

  def feature_enabled?
    unless Setting.get(:features, :groups) and (Site.current.max_groups.nil? or Site.current.max_groups > 0)
      redirect_to people_path
      false
    end
  end

end
