class MembershipsController < ApplicationController
  
  skip_before_filter :authenticate_user, :only => %w(show update)
  before_filter :authenticate_user_with_code_or_session, :only => %w(show update)
  
  def show
    # allow email links to work (since they will be GET requests)
    if params[:email]
      update
    else
      raise ActionController::UnknownAction, 'No action responded to show'
    end
  end
  
  def index
    @group = Group.find(params[:id])
    if @logged_in.can_edit?(@group)
      @requests = @group.membership_requests
    else
      render :text => 'You are not authorized to view membership requests for this group.', :layout => true, :status => 401
    end
  end
  
  # join group
  def create
    @group = Group.find(params[:group_id])
    @person = Person.find(params[:id])
    if @logged_in.can_edit?(@group)
      @group.memberships.create(:person => @person)
    elsif @person == @logged_in
      @group.membership_requests.create(:person => @person)
      flash[:warning] = 'A request to join this group has been sent to the group administrator(s).'
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
        flash[:notice] = 'Your email settings for the group have been changed.'
        redirect_back
      else  
        render :text => 'There was an error changing your email settings.', :layout => true, :status => 500
      end
    # promote/demote
    elsif @logged_in.can_edit?(@group)
      @membership = @group.memberships.find_or_create_by_person_id(params[:id])
      @membership.update_attribute :admin, !params[:promote].nil?
      flash[:notice] = 'User settings saved.'
      redirect_back
    else
      render :text => 'You are not authorized to perform this operation.', :layout => true, :status => 401
    end
  end
  
  # leave group
  def destroy
    @group = Group.find(params[:group_id])
    @membership = @group.memberships.find_by_person_id(params[:id])
    if @logged_in.can_edit?(@group) or @membership.person == @logged_in
      if @group.last_admin?(@membership.person)
        flash[:warning] = "#{person.name} is the last admin and cannot be removed."
      else
        @membership.destroy
      end
    end
    redirect_back
  end
  
  def batch
    @group = Group.find(params[:group_id])
    group_people = @group.people
    if @logged_in.can_edit?(@group)
      if params[:ids] and params[:ids].is_a?(Array)
        params[:ids].each do |id|
          if request.post?
            person = Person.find(id)
            @group.memberships.create(:person => person) unless group_people.include?(person)
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
        render :text => 'You must specify a list of ids.'
      end
    else
      render :text => 'You are not authorized to perform batch operations on this group.', :layout => true, :status => 401
    end
  end
  
end
