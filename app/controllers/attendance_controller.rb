class AttendanceController < ApplicationController
  
  def index
    @group = Group.find(params[:group_id])
    if @group.admin?(@logged_in)
      @attended_at = Date.parse(params[:attended_at])
      @records = @group.get_people_attendance_records_for_date(Time.zone.local_to_utc(@attended_at.to_time))
    else
      render :text => 'You are not authorized to view attendance for this group.', :layout => true, :status => 401
    end
  end
  
  def create
    @group = Group.find(params[:group_id])
    @attended_at = Date.parse(params[:attended_at])
    if @group.admin?(@logged_in)
      params[:ids].to_a.each do |id|
        if person = Person.find_by_id(id)
          @group.attendance_records.create!(:person_id => person.id, :attended_at => @attended_at.strftime('%Y-%m-%d'))
        end
      end
      @records = @group.get_people_attendance_records_for_date(@attended_at)
    else
      render :text => 'You are not authorized to record attendance for this group.', :layout => true, :status => 401
    end
  end
  
  def batch
    @group = Group.find(params[:group_id])
    @attended_at = Date.parse(params[:attended_at])
    if @group.admin?(@logged_in)
      @group.attendance_records.find_all_by_attended_at(Time.zone.local_to_utc(@attended_at.to_time)).each { |r| r.destroy }
      params[:ids].to_a.each do |id|
        if person = Person.find_by_id(id)
          @group.attendance_records.create!(:person_id => person.id, :attended_at => @attended_at.strftime('%Y-%m-%d'))
        end
      end
    else
      render :text => 'You are not authorized to record attendance for this group.', :layout => true, :status => 401
    end
  end
  
end
