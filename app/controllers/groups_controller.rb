class GroupsController < ApplicationController
  def index
    conditions = ['subscription = ?', false]
    conditions.add_condition ['category = ?', params[:category]] if params[:category]
    @groups = Group.find(
      :all,
      :conditions => conditions,
      :order => 'name'
    )
    @categories = Group.find_by_sql('select distinct category from groups').map { |g| g.category }.select { |c| c }
  end
  
  def view
    @group = Group.find params[:id]
    unless @logged_in.sees? @group
      render :text => 'This group is private.', :layout => true
    end
  end
  
  def edit
    if new_group = params[:id].nil?
      @group = Group.new :creator_id => @logged_in.id
    else
      @group = Group.find params[:id]
      unless @logged_in.can_edit? @group
        render :text => 'You are not authorized to edit this group.', :layout => true
        return
      end
    end
    @categories = Group.find_by_sql("select distinct category from groups where category is not null and category != ''").map { |g| g.category }
    if request.post?
      if params[:group]
        if not @logged_in.admin? and (params[:group][:address] or params[:group][:link_code] or params[:group][:subscription] or params[:group][:members_send])
          raise 'You are not authorized to do that.'
        end
        if @group.update_attributes params[:group]
          @group.memberships.create(:person => @logged_in, :admin => true) if new_group
          flash[:notice] = 'Group changes saved.'
        else
          flash[:notice] = @group.errors.full_messages.join('; ')
        end
      end
      if params[:photo]
        @group.photo = (params[:photo] == 'remove') ? nil : params[:photo]
      end
    end
  end
  
  def delete
    @group = Group.find params[:id]
    if @logged_in.can_edit? @group
      @group.destroy
      flash[:notice] = 'Group deleted.'
    else
      flash[:notice] = 'You are not authorized to delete this group.'
    end
    redirect_to :action => 'index'
  end
  
  def photo
    send_photo Group.find(params[:id].to_i)
  end
  
  def promote(admin=true)
    @group = Group.find params[:id]
    if @logged_in.can_edit? @group
      begin
        membership = @group.memberships.find_by_person_id params[:person_id]
        membership.update_attribute :admin, admin
        flash[:notice] = 'User settings saved.'
      rescue
        flash[:notice] = 'There was an error.'
      end
      redirect_to :action => 'edit', :id => group.id
    else
      redirect_to :action => 'view', :id => group.id
    end
  end
  
  def demote
    promote(false)
  end
  
  def add_people
    @group = Group.find params[:id]
    if @logged_in.can_edit? @group
      params[:people].each { |id| join id }
      redirect_to :action => 'edit', :id => @group
    else
      redirect_to :action => 'view', :id => @group
    end
  end
  
  def remove_people
    @group = Group.find params[:id]
    if @logged_in.can_edit? @group
      if params[:people]
        params[:people].each { |id| leave id }
      end
      redirect_to :action => 'edit', :id => @group
    else
      redirect_to :action => 'view', :id => @group
    end
  end
  
  def join(person_id=nil)
    @group = Group.find params[:id]
    raise 'You cannot join a private group' if @group.private? and person_id.nil? and not @group.admin? @logged_in
    id = person_id || @logged_in.id
    unless @group.memberships.find_all_by_person_id(id).any?
      @group.memberships.create :person => Person.find(id)
    end
    unless person_id
      flash[:notice] = 'You are now in this group.'
      redirect_to :action => 'view', :id => @group
    end
  end
  
  def leave(person_id=nil)
    @group = Group.find params[:id]
    id = person_id || @logged_in.id
    @group.memberships.find_all_by_person_id(id).each do |m|
      m.destroy unless @group.last_admin?(m.person)
    end
    unless person_id
      flash[:notice] = 'You are no longer in that group.'
      redirect_to :action => 'index'
    end
  end
  
  def toggle_email
    @group = Group.find params[:id]
    @person = Person.find params[:person_id]
    if @logged_in.can_edit? @group or @logged_in == @person
      options = @group.get_options_for @person
      get_email = !(options.nil? or options.get_email)
      @group.set_options_for @person, {:get_email => get_email}
    end
    redirect_to params[:from] || {:action => 'view', :id => @group}
  end
end
