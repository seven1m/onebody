class AttendanceController < ApplicationController

  skip_before_filter :authenticate_user,
    if: -> c { %w(index batch).include?(c.action_name) and params[:public] }

  def index
    @group = Group.find(params[:group_id])
    if @group.admin?(@logged_in) or (params[:token].present? and @group.share_token == params[:token])
      if @group.attendance?
        begin
          @attended_at = params[:attended_at] ? Date.parse_in_locale(params[:attended_at]) : Date.today
        rescue ArgumentError
          flash[:warning] = t('attendance.wrong_date_format')
          @attended_at = Date.today
        end
        @records = @group.get_people_attendance_records_for_date(@attended_at)
        if params[:public]
          render action: 'public_index', layout: 'signed_out'
        end
      else
        render text: t('attendance.not_enabled'), layout: true, status: 500
      end
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  # this method is similar to batch, but does not clear all the existing records for the group first
  # this method also allows you to record attendance for people not in the database (used for checkin 'add a friend' feature)
  def create
    @group = params[:group_id].to_i > 0 ? Group.find(params[:group_id]) : nil
    @attended_at = Time.parse(params[:attended_at])
    if @logged_in.super_admin? or @group.admin?(@logged_in)
      Array(params[:ids]).each do |id|
        if person = Person.where(id: id).first
          AttendanceRecord.delete_all(["person_id = ? and attended_at = ?", id, @attended_at.strftime('%Y-%m-%d %H:%M:%S')])
          if @group
            @group.attendance_records.create!(
              person_id:      person.id,
              attended_at:    @attended_at.strftime('%Y-%m-%d %H:%M:%S'),
              first_name:     person.first_name,
              last_name:      person.last_name,
              family_name:    person.family.name,
              age:            person.age_group,
              can_pick_up:    person.can_pick_up,
              cannot_pick_up: person.cannot_pick_up,
              medical_notes:  person.medical_notes
            )
          end
        end
      end
      # record attendance for a person not in database (one at a time)
      if person = params[:person] and @group
        @group.attendance_records.create!(
          attended_at:    @attended_at.strftime('%Y-%m-%d %H:%M:%S'),
          first_name:     person['first_name'],
          last_name:      person['last_name'],
          age:            person['age']
        )
      end
      respond_to do |format|
        format.html do
          if @group
            redirect_to group_attendance_index_path(@group, attended_at: @attended_at)
          else
            render text: t('attendance.saved'), layout: true
          end
        end
        format.json { render text: {'status' => 'success'}.to_json }
      end
    else
      render text: t('not_authorized'), layout: true, status: 401
    end
  end

  # this method clears all existing attendance for the entire date and adds what is sent in params
  def batch
    @group = Group.find(params[:group_id])
    unless @attended_at = Time.parse_in_locale(params[:attended_at]) || Date.parse_in_locale(params[:attended_at])
      render_text t('attendance.wrong_date_format'), :bad_request
      return
    end
    if @group.admin?(@logged_in) or (params[:token].present? and @group.share_token == params[:token])
      @group.attendance_records_for_date(@attended_at).delete_all
      attendance_records = Array(params[:ids]).map do |id|
        next unless person = Person.where(id: id).first
        @group.attendance_records.create!(
          person_id:      person.id,
          attended_at:    @attended_at.strftime('%Y-%m-%d %H:%M:%S'),
          first_name:     person.first_name,
          last_name:      person.last_name,
          family_name:    person.family.name,
          age:            person.age_group,
          can_pick_up:    person.can_pick_up,
          cannot_pick_up: person.cannot_pick_up,
          medical_notes:  person.medical_notes
        )
      end.compact
      if params[:public]
        if params[:notes].present?
          Notifier.attendance_submission(@group, attendance_records, @logged_in, params[:notes]).deliver
        end
        render_text t('attendance.saved')
      else
        Notifier.attendance_submission(@group, attendance_records, @logged_in, params[:notes]).deliver
        flash[:notice] = t('changes_saved')
        redirect_to group_attendance_index_path(@group, attended_at: @attended_at.to_s(:date))
      end
    else
      render_text t('not_authorized'), :unauthorized
    end
  end

  protected

  def render_text(message, status=:ok)
    respond_to do |format|
      format.html { render text: message, layout: 'signed_out', status: status }
      format.json { render json: { status: status, message: message } }
    end
  end

end
