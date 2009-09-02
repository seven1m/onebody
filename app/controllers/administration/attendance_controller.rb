class Administration::AttendanceController < ApplicationController

  before_filter :only_admins

  def index
    @attended_at = params[:attended_at] ? Date.parse(params[:attended_at]) : Date.today
    respond_to do |format|
      format.html do
        @records = AttendanceRecord.paginate(
          :page => params[:page],
          :conditions => ["attended_at = ?", Time.zone.local_to_utc(@attended_at.to_time)],
          :order => 'group_id',
          :include => %w(person group)
        )
      end
      format.csv do
        @records = AttendanceRecord.all(
          :conditions => ["attended_at = ?", Time.zone.local_to_utc(@attended_at.to_time)],
          :order => 'group_id',
          :select => 'attendance_records.*, people.first_name, people.last_name, groups.name as group_name',
          :joins => [:person, :group]
        )
        CSV::Writer.generate(csv_str = '') do |csv|
          csv << %w(group_name group_id first_name last_name person_id date)
          @records.each do |record|
            csv << [
              record.group_name,
              record.group_id,
              record.first_name,
              record.last_name,
              record.person_id,
              record.attended_at.strftime('%Y-%m-%d')
            ]
          end
        end
        render :text => csv_str
      end
    end
  end
  
  private
  
    def only_admins
      unless @logged_in.admin?(:manage_attendance)
        render :text => 'You must be an administrator to use this section.', :layout => true, :status => 401
        return false
      end
    end

end
