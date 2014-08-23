class Administration::Checkin::GroupsController < ApplicationController

  before_filter :only_admins

  def index
    @time = CheckinTime.find(params[:time_id]).decorate
    @entries = @time.entries
    @labels = CheckinLabel.all.order(:name)
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
    if @group_time = GroupTime.find(params[:id])
      @group_time.attributes = params.permit(:label_id, :print_extra_nametag)
      @group_time.save
    end
  end

  def destroy
    @entry = find_entry(params[:id])
    @entry.destroy
    redirect_to administration_checkin_time_groups_path(@entry.time)
  end

  def reorder
    @entry = find_entry(params[:id])
    @entry.parent.reorder_entry(@entry, params[:direction], params[:full_stop].present?)
    respond_to do |format|
      format.html { redirect_to administration_checkin_time_groups_path(@entry.time) }
      format.js
    end
  end

  private

  def find_entry(id)
    if id.sub!(/group_time_/, '')
      GroupTime.find(id)
    elsif id.sub!(/checkin_folder_/, '')
      CheckinFolder.find(id)
    else
      raise "could not find record by id #{id}"
    end
  end

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
