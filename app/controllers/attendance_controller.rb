class AttendanceController < ApplicationController
  skip_before_action :authenticate_user,
                     if: ->(c) { %w(index batch).include?(c.action_name) && params[:public] }

  before_action :eliminate_checkin_error # TEMP

  load_parent :group, optional: true
  before_action :authorize_group
  before_action :ensure_attendance_enabled_for_group

  def index
    @attended_at = Date.parse_in_locale(params[:attended_at]) || begin
      if params[:attended_at].present?
        flash[:warning] = t('attendance.wrong_date_format')
      end
      Date.current
    end
    @records = @group.get_people_attendance_records_for_date(@attended_at, order_by_last: params[:order] == 'last')
    render action: 'public_index', layout: 'signed_out' if params[:public]
  end

  # this method is similar to batch, but does not clear all the existing records for the group first
  # this method also allows you to record attendance for people not in the database (used for checkin 'add a friend' feature)
  def create
    batch = AttendanceBatch.new(@group, params[:attended_at])
    batch.update(params[:ids])
    batch.create_unlinked(params[:person]) if params[:person]
    respond_to do |format|
      format.html do
        redirect_to group_attendance_index_path(@group, attended_at: batch.attended_at)
      end
      format.json do
        render json: { status: 'success' }
      end
    end
  end

  # this method clears all existing attendance for the entire date and adds what is sent in params
  def batch
    batch = AttendanceBatch.new(@group, params[:attended_at])
    unless batch.attended_at
      render_text t('attendance.wrong_date_format'), :bad_request
      return
    end
    batch.clear_all_for_date
    attendance_records = batch.update(params[:ids])
    if params[:public]
      if params[:notes].present?
        Notifier.attendance_submission(@group, attendance_records, @logged_in, params[:notes]).deliver_now
      end
      render_text t('attendance.saved')
    else
      Notifier.attendance_submission(@group, attendance_records, @logged_in, params[:notes]).deliver_now
      flash[:notice] = t('changes_saved')
      redirect_to group_attendance_index_path(@group, attended_at: batch.attended_at.to_s(:date))
    end
  end

  protected

  def render_text(message, status = :ok)
    respond_to do |format|
      format.html { render plain: message, layout: 'signed_out', status: status }
      format.json { render json: { status: status, message: message } }
    end
  end

  def authorize_group
    unless @group.admin?(@logged_in) || authorized_with_token?
      render_text t('not_authorized'), :unauthorized
      false
    end
  end

  def authorized_with_token?
    params[:token].present? && @group && @group.share_token == params[:token]
  end

  def ensure_attendance_enabled_for_group
    unless @group && @group.attendance?
      render plain: t('attendance.not_enabled'), layout: true, status: :bad_request
      false
    end
  end

  # TEMP - this is only needed due to legacy check-in software
  # submitting bogus attendance (that can be ignored) at /groups/0/attendance.json
  def eliminate_checkin_error
    if params[:group_id] == '0' && params[:action] == 'create'
      render status: 404, plain: 'group not found'
      false
    end
  end
end
