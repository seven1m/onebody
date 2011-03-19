class MembershipsController < ApplicationController

  skip_before_filter :authenticate_user, :only => %w(show update)
  before_filter :authenticate_user_with_code_or_session, :only => %w(show update)

  cache_sweeper :membership_sweeper, :only => %w(create update destroy batch)

  def show
    # allow email links to work (since they will be GET requests)
    if params[:email]
      update
    else
      raise ActionController::UnknownAction, t('No_action_to_show')
    end
  end

  def index
    @group = Group.find(params[:group_id])
    @can_edit = @logged_in.can_edit?(@group)
    if @logged_in.can_see?(@group)
      @requests = @group.membership_requests
    else
      render :text => t('not_authorized'), :layout => true, :status => 401
    end
  end

  # join group
  def create
    @group = Group.find(params[:group_id])
    @person = Person.find(params[:id])
    if @logged_in.can_edit?(@group) or not @group.approval_required_to_join?
      @group.memberships.create(:person => @person)
    elsif me?
      @group.membership_requests.create(:person => @person)
      flash[:warning] = t('groups.request_sent')
    end
    redirect_back
  end

  def update
    @group = Group.find(params[:group_id])
    # email on/off
    if params[:email]
      @person = Person.find(params[:id])
      if @logged_in.can_edit?(@group) or @logged_in.can_edit?(@person)
        @group.set_options_for @person, {:get_email => (params[:email] == 'on')}
        flash[:notice] = t('groups.email_settings_changed')
        redirect_back
      else
        render :text => t('There_was_an_error'), :layout => true, :status => 500
      end
    # promote/demote
    elsif @logged_in.can_edit?(@group)
      @membership = @group.memberships.find_or_create_by_person_id(params[:id])
      @membership.update_attribute :admin, !params[:promote].nil?
      flash[:notice] = t('groups.user_settings_saved')
      redirect_back
    else
      render :text => t('not_authorized'), :layout => true, :status => 401
    end
  end

  # leave group
  def destroy
    @group = Group.find(params[:group_id])
    @membership = @group.memberships.find_by_person_id(params[:id])
    if @logged_in.can_edit?(@group) or @membership.try(:person) == @logged_in
      if @membership.person and @group.last_admin?(@membership.person)
        flash[:warning] = t('groups.last_admin_remove', :name => @membership.person.name)
      else
        @membership.destroy
      end
    end
    respond_to do |format|
      format.html { redirect_back }
      format.js
    end
  end

  def batch
    if params[:person_id]
      batch_on_person
    else
      batch_on_group
    end
  end

  def batch_on_person
    @person = Person.find(params[:person_id])
    if @logged_in.can_edit?(@person) and @logged_in.admin?(:manage_groups)
      groups = (params[:ids] || []).map { |id| Group.find(id) }
      # add groups
      (groups - @person.groups).each do |group|
        group.memberships.create(:person => @person)
      end
      # remove groups
      (@person.groups - groups).each do |group|
        group.memberships.find_by_person_id(@person.id).destroy unless group.last_admin?(@person)
      end
      @person.groups.reload
      respond_to do |format|
        format.js
      end
    else
      render :text => t('not_authorized'), :layout => true, :status => 401
    end
  end

  def batch_on_group
    @group = Group.find(params[:group_id])
    group_people = @group.people
    if @logged_in.can_edit?(@group)
      @can_edit = true
      if params[:ids] and params[:ids].is_a?(Array)
        @added = []
        params[:ids].each do |id|
          if request.post?
            person = Person.find(id)
            unless params[:commit] == 'Ignore' or group_people.include?(person)
              @group.memberships.create(:person => person) 
              @added << person
            end
            @group.membership_requests.find_all_by_person_id(id).each { |r| r.destroy }
          elsif request.delete?
            if @membership = @group.memberships.find_by_person_id(id)
              @membership.destroy unless @group.last_admin?(@membership.person)
            end
          end
        end
        respond_to do |format|
          format.js
          format.html { redirect_back }
        end
      else
        render :text => t('groups.must_specify_ids_list')
      end
    else
      render :text => t('not_authorized'), :layout => true, :status => 401
    end
  end

  def birthdays
    @group = Group.find(params[:group_id])
    if @logged_in.can_edit?(@group)
      @people = @group.people.where('birthday is not null').order("#{sql_month 'people.birthday'}, #{sql_day 'people.birthday'}, people.last_name, people.first_name")
    else
      render :text => t('not_authorized'), :layout => true, :status => 401
    end
  end

end
