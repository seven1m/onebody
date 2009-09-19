class Administration::CheckinGroupsController < ApplicationController
  
  before_filter :only_admins
  
  def index
    @times = CheckinTime.recurring + CheckinTime.upcoming_singles
    @groups = Group.all(:order => 'name').group_by &:category
  end
  
  # drag-drop a group onto a time box
  def create
    @group = Group.find(params[:id].split('_').last.to_i)
    @time = CheckinTime.find(params[:time_id])
    if @group.group_times.find_by_checkin_time_id(@time.id)
      render :nothing => true
    else
      @group.group_times.create(:checkin_time => @time)
      @groups = @time.groups
    end
  end
  
  def destroy
    @time = CheckinTime.find(params[:time_id])
    GroupTime.find_by_group_id_and_checkin_time_id(params[:id], @time.id).destroy
    @groups = @time.groups
    render :action => 'create'
  end
  
  def reorder
    params["groups_for_time_#{params[:time_id]}"].to_a.each_with_index do |id, index|
      t = GroupTime.find_by_group_id_and_checkin_time_id(id, params[:time_id])
      t.update_attribute(:ordering, index+1)
    end
    render :nothing => true
  end
  
  private
  
    def only_admins
      unless @logged_in.admin?(:manage_checkin)
        render :text => 'You must be an administrator to use this section.', :layout => true, :status => 401
        return false
      end
    end
  
end
