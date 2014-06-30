class Checkin::CheckinsController < ApplicationController

  skip_before_filter :authenticate_user
  before_filter :ensure_campus_selection
  before_filter :reset_family, except: :edit

  layout 'checkin'

  def show
    render action: 'new'
  end

  def new
  end

  def create
    if @family = Family.undeleted.by_barcode(params[:barcode]).first
      session[:checkin_family_id] = @family.id
      redirect_to edit_checkin_path
    else
      flash[:error] = 'card unknown'
      render action: 'new'
    end
  end

  def edit
    return redirect_to(action: 'show') unless session[:checkin_family_id]
    @family = Family.find(session[:checkin_family_id])
    @checkins = @family.people.undeleted.map do |person|
      CheckinPresenter.new(session[:checkin_campus], person)
    end
  end

  # FIXME yuck this is huge
  # move this logic into GroupTime or AttendanceRecord, or create a new service object????
  def update
    labels = {}
    params[:people].each do |person_id, group_time_ids|
      person = Person.find(person_id)
      group_times = GroupTime.find(group_time_ids)
      group_times.each do |group_time_id|
        group_time = GroupTime.find(group_time_id)
        attended_at = group_time.checkin_time.the_datetime || Time.parse(group_time.checkin_time.time_to_s)
        AttendanceRecord.where(person_id: person.id, attended_at: attended_at).delete_all
        attendance_record = group_time.group.attendance_records.create!(
          person_id:      person.id,
          attended_at:    attended_at,
          first_name:     person.first_name,
          last_name:      person.last_name,
          family_name:    person.family.name,
          age:            person.age_group,
          can_pick_up:    person.can_pick_up,
          cannot_pick_up: person.cannot_pick_up,
          medical_notes:  person.medical_notes
        )
        ## record attendance for a person not in database (one at a time)
        #if person = params[:person] and @group
          #@group.attendance_records.create!(
            #attended_at:    @attended_at.strftime('%Y-%m-%d %H:%M:%S'),
            #first_name:     person['first_name'],
            #last_name:      person['last_name'],
            #age:            person['age']
          #)
        #end
        labels[person.id] ||= []
        labels[person.id] << attendance_record.as_json if group_time.print_nametag? and labels[person.id].empty?
        labels[person.id] << attendance_record.as_json if group_time.print_extra_nametag? and labels[person.id].length < 2
      end
    end
    session.delete(:checkin_family_id)
    render json: { labels: labels }
  end

  private

  def ensure_campus_selection
    if params[:campus]
      session[:checkin_campus] = params[:campus]
    elsif not session[:checkin_campus]
      if (@campuses = CheckinTime.campuses).length == 1
        session[:checkin_campus] = @campuses.first
      else
        render action: 'campus_select'
        return false
      end
    end
  end

  def reset_family
    #session.delete(:checkin_family_id) # TODO
  end

end
