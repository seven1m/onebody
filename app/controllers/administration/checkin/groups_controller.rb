class Administration::Checkin::GroupsController < ApplicationController
  before_action :only_admins

  def index
    @time = CheckinTime.find(params[:time_id]).decorate
    @entries = @time.entries
    @labels = CheckinLabel.all.order(:name)
  end

  def create
    @time = CheckinTime.find(params[:time_id])
    if params[:folder]
      create_folder
    else
      create_group
    end
    respond_to do |format|
      format.html { redirect_to edit_administration_checkin_time_path(@time) }
      format.js do
        @labels = CheckinLabel.all.order(:name)
        @entries = @time.entries
      end
    end
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
    respond_to do |format|
      format.html { redirect_to administration_checkin_time_groups_path(@entry.time) }
      format.js
    end
  end

  def reorder
    @entry = find_entry(params[:id])
    if params[:jump_into]
      find_entry(params[:jump_into]).insert(@entry, params[:direction] == 'up' ? :bottom : :top)
    elsif params[:jump_out]
      @entry.remove_from_checkin_folder(params[:direction] == 'up' ? :above : :below)
    else
      @entry.parent.reorder_entry(@entry, params[:direction], params[:full_stop].present?)
    end
    @time = @entry.time
    respond_to do |format|
      format.html { redirect_to administration_checkin_time_groups_path(@time) }
      format.js do
        @labels = CheckinLabel.all.order(:name)
        @entries = @time.entries
      end
    end
  end

  private

  def create_folder
    @added = [@time.checkin_folders.create!(name: params[:name])]
  end

  def create_group
    @added = Array(params[:ids]).map do |id|
      group = Group.find(id)
      group.update_attribute(:attendance, true)
      opts = if params[:checkin_folder_id].present?
               { checkin_folder_id: params[:checkin_folder_id] }
             else
               { checkin_time_id: @time.id }
      end
      # NOTE cannot use first_or_create here due to https://github.com/rails/rails/issues/16668
      group.group_times.create!(opts) unless group.group_times.where(opts).any?
    end.compact
  end

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
      render html: 'You must be an administrator to use this section.', layout: true, status: 401
      false
    end
  end

  def feature_enabled?
    unless Setting.get(:features, :checkin)
      render html: 'This feature is unavailable.', layout: true
      false
    end
  end
end
