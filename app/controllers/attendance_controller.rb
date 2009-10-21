class AttendanceController < ApplicationController
  
  def index
    @group = Group.find(params[:group_id])
    if @group.admin?(@logged_in)
      if @group.attendance?
        begin
          @attended_at = params[:attended_at] ? Date.parse(params[:attended_at]) : Date.today
        rescue ArgumentError
          flash[:warning] = "Please enter the date as YYYY/MM/DD."
          @attended_at = Date.today
        end
        @records = @group.get_people_attendance_records_for_date(@attended_at)
      else
        render :text => 'Attendance tracking is not enabled for this goup.', :layout => true, :status => 500
      end
    else
      render :text => 'You are not authorized to view attendance for this group.', :layout => true, :status => 401
    end
  end
  
  # this method is similar to batch, but does not clear all the existing records for the group first
  # this method also allows you to record attendance for people not in the database (used for checkin 'add a friend' feature)
  def create
    @group = params[:group_id].to_i > 0 ? Group.find(params[:group_id]) : nil
    @attended_at = Time.parse(params[:attended_at])
    if @group.admin?(@logged_in)
      params[:ids].to_a.each do |id|
        if person = Person.find_by_id(id)
          AttendanceRecord.delete_all(["person_id = ? and attendance_records.attended_at = ?", id, @attended_at])
          if @group
            @group.attendance_records.create!(
              :person_id      => person.id,
              :attended_at    => @attended_at,
              :first_name     => person.first_name,
              :last_name      => person.last_name,
              :family_name    => person.family.name,
              :age            => person.age_group,
              :can_pick_up    => person.can_pick_up,
              :cannot_pick_up => person.cannot_pick_up,
              :medical_notes  => person.medical_notes
            )
          end
        end
      end
      # record attendance for a person not in database (one at a time)
      if person = params[:person] and @group
        @group.attendance_records.create!(
          :attended_at    => @attended_at,
          :first_name     => person['first_name'],
          :last_name      => person['last_name'],
          :age            => person['age']
        )
      end
      respond_to do |format|
        format.html do
          if @group
            redirect_to group_attendance_index_path(@group, :attended_at => @attended_at)
          else
            render :text => 'Attendance saved.', :layout => true
          end
        end
        format.json { render :text => {'status' => 'success'}.to_json }
      end
    else
      render :text => 'You are not authorized to record attendance for this group.', :layout => true, :status => 401
    end
  end
  
  # this method clears all existing attendance for the entire date and adds what is sent in params
  def batch
    @group = Group.find(params[:group_id])
    @attended_at = Time.parse(params[:attended_at])
    if @group.admin?(@logged_in)
      @group.attendance_records.find_all_by_attended_at(@attended_at).each { |r| r.destroy }
      params[:ids].to_a.each do |id|
        if person = Person.find_by_id(id)
          @group.attendance_records.create!(
            :person_id      => person.id,
            :attended_at    => @attended_at,
            :first_name     => person.first_name,
            :last_name      => person.last_name,
            :family_name    => person.family.name,
            :age            => person.age_group,
            :can_pick_up    => person.can_pick_up,
            :cannot_pick_up => person.cannot_pick_up,
            :medical_notes  => person.medical_notes
          )
        end
      end
      redirect_to group_attendance_index_path(@group, :attended_at => @attended_at)
    else
      render :text => 'You are not authorized to record attendance for this group.', :layout => true, :status => 401
    end
  end
  
end
