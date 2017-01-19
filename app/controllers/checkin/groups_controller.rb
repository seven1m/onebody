class Checkin::GroupsController < ApplicationController

  def index
    @groups = {}
    date = params[:date] ? Date.parse(params[:date]) : Date.current
    CheckinTime.for_date(date, params[:campus]).each do |time|
      @groups[time.time_to_s] = time.all_group_times.order('group_times.sequence')
                                                    .includes(:group, :checkin_folder)
                                                    .references(:groups, :checkin_folders)
                                                    .select('group_times.label_id, checkin_folders.name, groups.*')
                                                    .map { |gt| [gt.group_id, gt.group.name, !!gt.label_id, gt.group.link_code, gt.checkin_folder.try(:name)] }
                                                    .group_by { |g| g[4].to_s }
    end
    respond_to do |format|
      format.json do
        render :text => {
          'groups'     => @groups,
          'updated_at' => GroupTime.order('updated_at').last.updated_at
        }.to_json
      end
    end
  end

end
