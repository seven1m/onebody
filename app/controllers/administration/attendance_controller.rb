class Administration::AttendanceController < ApplicationController

  before_filter :only_admins

  def index
    @attended_at = params[:attended_at] ? Date.parse(params[:attended_at]) : Date.today
    @groups = AttendanceRecord.groups_for_date(@attended_at)
    unless params[:sort].to_s.split(',').all? { |col| %w(attendance_records.last_name attendance_records.first_name groups.name attendance_records.attended_at attendance_records.created_at).include?(col) }
      params[:sort] = 'groups.name'
    end
    conditions = ["attended_at >= ? and attended_at <= ?", @attended_at.strftime('%Y-%m-%d 0:00'), @attended_at.strftime('%Y-%m-%d 23:59:59')]
    conditions.add_condition(["group_id = ?", params[:group_id]]) if params[:group_id].to_i > 0
    respond_to do |format|
      format.html do
        @records = AttendanceRecord.paginate(
          :page       => params[:page],
          :conditions => conditions,
          :order      => params[:sort],
          :include    => %w(person group)
        )
      end
      format.csv do
        @records = AttendanceRecord.all(
          :conditions => conditions,
          :order      => 'group_id',
          :select     => 'attendance_records.*, people.first_name, people.last_name, groups.name as group_name',
          :joins      => [:person, :group]
        )
        CSV::Writer.generate(csv_str = '') do |csv|
          csv << %w(group_name group_id first_name last_name person_id time)
          @records.each do |record|
            csv << [
              record.group_name,
              record.group_id,
              record.first_name,
              record.last_name,
              record.person_id,
              record.attended_at.to_s
            ]
          end
        end
        render :text => csv_str
      end
    end
  end
  
  def destroy
    @record = AttendanceRecord.find(params[:id])
    @record.destroy
    redirect_to administration_attendance_index_path(:attended_at => @record.attended_at.to_date)
  end
  
  private
  
    def only_admins
      unless @logged_in.admin?(:manage_attendance)
        render :text => 'You must be an administrator to use this section.', :layout => true, :status => 401
        return false
      end
    end

end
