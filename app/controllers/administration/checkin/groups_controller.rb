class Administration::Checkin::GroupsController < ApplicationController

  before_filter :only_admins

  def index
    @time = CheckinTime.find(params[:time_id])
    @group_times = @time.group_times
    @labels = CheckinLabel.all.order(:name)
    @sections = GroupTime.distinct(:section).pluck(:section)
  end

  def create
    @time = CheckinTime.find(params[:time_id])
    Array(params[:ids]).each do |id|
      group = Group.find(id)
      unless group.group_times.where(checkin_time_id: @time.id).any?
        group.group_times.create(checkin_time: @time)
      end
    end
    redirect_to edit_administration_checkin_time_path(@time)
  end

  def update
    @time = CheckinTime.find(params[:time_id])
    if @group_time = @time.group_times.where(group_id: params[:id]).first
      @group_time.attributes = params.permit(:label_id, :print_extra_nametag, :section)
      @group_time.save
    end
  end

  def destroy
    @time = CheckinTime.find(params[:time_id])
    GroupTime.where(group_id: params[:id], checkin_time_id: @time.id).destroy_all
    redirect_to administration_checkin_time_groups_path(@time)
  end

  def reorder
    @group_time = GroupTime.find(params[:id])
    @time = @group_time.checkin_time
    @time.reorder_group(@group_time, params[:direction])
    redirect_to administration_checkin_time_groups_path(@time)
  end

  private

  def only_admins
    unless @logged_in.admin?(:manage_checkin)
      render text: 'You must be an administrator to use this section.', layout: true, status: 401
      return false
    end
  end

  def feature_enabled?
    unless Setting.get(:features, :checkin)
      render text: 'This feature is unavailable.', layout: true
      false
    end
  end
end
