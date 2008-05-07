class GroupsController < ApplicationController
  def index
    @categories = Group.find_by_sql("select category, count(*) as group_count from groups where category is not null and category != '' and category != 'Subscription' #{@logged_in.admin?(:manage_groups) ? '' : 'and hidden = 0 and approved = 1'} group by category").map { |g| [g.category, g.group_count] }
    @hidden_groups = Group.find_all_by_hidden(true, :order => 'name')
    if @logged_in.admin?(:manage_groups)
      @unapproved_groups = Group.find_all_by_approved(false)
    else
      @unapproved_groups = Group.find_all_by_creator_id_and_approved(@logged_in.id, false)
    end
    @person = @logged_in
  end
  
  def search
    conditions = []
    conditions.add_condition ['hidden = ? and approved = ?', false, true] unless @logged_in.admin?(:manage_groups)
    conditions.add_condition ['category = ?', params[:category]] if params[:category]
    conditions.add_condition ['name like ?', '%' + params[:name] + '%'] if params[:name]
    @groups = Group.find(:all, :conditions => conditions, :order => 'name')
    conditions[1] = true # only hidden groups
    @hidden_groups = Group.find(:all, :conditions => conditions, :order => 'name')
  end
  
  def view
    @group = Group.find params[:id]
    @messages = @group.messages.find :all, :select => '*, (select count(*) from messages r where r.parent_id=messages.id and r.to_person_id is null) as reply_count, (select count(*) from attachments where message_id=messages.id or message_id in (select id from messages r where r.parent_id=messages.id)) as attachment_count'
    @notes = @group.notes.find_all_by_deleted(false, :order => 'created_at desc', :limit => 10)
    @prayer_requests = @group.prayer_requests.find(:all, :conditions => "answer = '' or answer is null", :order => 'created_at desc')
    @answered_prayer_count = @group.prayer_requests.count('*', :conditions => "answer != '' and answer is not null")
    unless @group.approved? or @group.admin?(@logged_in)
      render :text => 'This group is pending approval', :layout => true
    end
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
      @unlinked_ids = @group.unlinked_members.map { |p| p.id }
    end
    @categories = Group.find_by_sql("select distinct category from groups where category is not null and category != ''").map { |g| g.category }
    if request.post?
      if params[:group]
        if not @logged_in.admin?(:manage_groups) and (params[:group][:address] or params[:group][:link_code] or params[:group][:members_send] or params[:group][:private])
          raise 'You are not authorized to do that.'
        end
        params[:group].cleanse 'address'
        if @group.update_attributes params[:group]
          if new_group
            if @logged_in.admin?(:manage_groups)
              @group.update_attribute(:approved, true)
              flash[:notice] = 'The group has been created.'
            else
              @group.memberships.create(:person => @logged_in, :admin => true)
              flash[:notice] = 'Your group has been created and is pending approval.'
            end
          else
            flash[:notice] = 'Group changes saved.'
          end
        else
          flash[:notice] = @group.errors.full_messages.join('; ')
        end
      end
      unless @group.errors.any?
        if params[:photo]
          if params[:photo] == 'remove'
            @group.photo = nil
          elsif params[:photo].size > 0
            @group.photo = params[:photo]
          end
        end
        redirect_to :action => 'edit', :id => @group
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
      redirect_to :action => 'edit', :id => @group.id
    else
      redirect_to :action => 'view', :id => @group.id
    end
  end
  
  def demote
    promote(false)
  end
  
  def add_people
    @group = Group.find params[:id]
    if @logged_in.can_edit? @group and @group.approved
      params[:people].each { |id| join id } if params[:people]
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
    id = person_id || @logged_in.id
    if person_id or @group.admin?(@logged_in) # just do it
      unless @group.memberships.find_all_by_person_id(id).any?
        @group.memberships.create :person => Person.find(id)
      end
    else # send a request
      unless @group.membership_requests.find_all_by_person_id(id).any?
        @group.membership_requests.create :person => Person.find(id)
        flash[:warning] = 'A request to join this group has been sent to the group administrator(s).'
      end
    end
    redirect_to params[:return_to] || {:action => 'view', :id => @group} unless person_id
  end
  
  def leave(person_id=nil)
    @group = Group.find params[:id]
    id = person_id || @logged_in.id
    @group.memberships.find_all_by_person_id(id).each do |m|
      m.destroy unless @group.last_admin?(m.person)
    end
    unless person_id
      flash[:notice] = 'You are no longer signed up.'
      redirect_to params[:return_to] || {:action => 'index'}
    end
  end
  
  def membership_requests
    @group = Group.find params[:id]
    raise 'Unauthorized' unless @group.admin?(@logged_in)
  end
  
  def process_requests
    @group = Group.find params[:id]
    raise 'Unauthorized' unless @group.admin?(@logged_in)
    params[:people].to_a.each do |id|
      @group.membership_requests.find_all_by_person_id(id).each do |req|
        join(id) if params[:commit] == 'Accept'
        req.destroy
      end
    end
    redirect_to :action => 'membership_requests', :id => @group.id
  end
  
  def toggle_email
    @group = Group.find params[:id]
    @person = Person.find params[:person_id] || params['amp;person_id'] # ??? This fixes the spider test, but it shouldn't be needed!
    @options = @group.get_options_for(@person, true)
    if params[:code].to_i > 0 and @options.code and params[:code].to_i == @options.code
      if request.post?
        Person.logged_in = @person 
        @group.set_options_for @person, {:get_email => !@options.get_email}
        render :text => "Your email preferences for the group #{@group.name} have been saved.", :layout => true
      else
        render :action => 'toggle_email'
      end
    elsif @logged_in and (@logged_in.can_edit?(@group) or @logged_in == @person or @logged_in.family_id == @person.family_id)
      @group.set_options_for @person, {:get_email => !@options.get_email}
      redirect_to params[:from] || group_url(:id => @group)
    else
      raise 'There was an error changing your email settings.'
    end
  end
  
  def approve
    if request.post? and @logged_in.admin?(:manage_groups)
      group = Group.find params[:id]
      group.update_attribute :approved, true
      flash[:notice] = 'The group has been approved.'
    end
    redirect_to :action => 'view', :id => group
  end
end
