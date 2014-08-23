class Checkin::GroupsController < ApplicationController

  def index
    @groups = {}
    date = params[:date] ? Date.parse(params[:date]) : Date.today
    CheckinTime.for_date(date, params[:campus]).each do |time|
      @groups[time.time_to_s] = time.groups.order('group_times.sequence')
                                           .select('group_times.label_id, group_times.section, groups.*')
                                           .map { |g| [g.id, g.name, !!g.label_id, g.link_code, g.section] }
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
