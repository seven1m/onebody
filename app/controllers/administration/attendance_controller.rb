class Administration::AttendanceController < ApplicationController

  before_filter :only_admins

  VALID_SORT_COLS = %w(
    attendance_records.last_name
    attendance_records.first_name
    groups.name
    attendance_records.attended_at
    attendance_records.created_at
  )

  # TODO refactor
  def index
    @attended_at = params[:attended_at] ? Date.parse(params[:attended_at]) : Date.today
    @groups = AttendanceRecord.groups_for_date(@attended_at)
    conditions = ["attended_at >= ? and attended_at <= ?", @attended_at.strftime('%Y-%m-%d 0:00'), @attended_at.strftime('%Y-%m-%d 23:59:59')]
    if params[:group_id].to_i > 0
      @group = Group.find(params[:group_id])
      conditions.add_condition(["group_id = ?", @group.id])
      params[:sort] ||= 'attendance_records.last_name,attendance_records.first_name'
    end
    if params[:person_name]
      conditions.add_condition(["concat(attendance_records.first_name, ' ', attendance_records.last_name) like ?", "%#{params[:person_name]}%"])
    end
    unless params[:sort].to_s.split(',').all? { |col| VALID_SORT_COLS.include?(col) }
      params[:sort] = 'groups.name'
    end
    respond_to do |format|
      format.html do
        @record_count = AttendanceRecord.count(
          conditions: conditions,
          include:    %w(person group)
        )
        @records = AttendanceRecord.paginate(
          page:       params[:page],
          conditions: conditions,
          order:      params[:sort],
          include:    %w(person group),
          per_page:   100
        )
      end
      format.csv do
        @records = AttendanceRecord.where(conditions).order(:group_id).joins(:person, :group) \
          .select('attendance_records.*, people.first_name, people.last_name, people.legacy_id, groups.name as group_name, groups.link_code as group_link_code')
        CSV::Writer.generate(csv_str = '') do |csv|
          csv << %w(group_name group_id group_link_code first_name last_name person_id person_legacy_id class_time recorded_time)
          @records.each do |record|
            csv << [
              record.group_name,
              record.group_id,
              record.group_link_code,
              record.first_name,
              record.last_name,
              record.person_id,
              record.legacy_id,
              record.attended_at.to_s,
              record.created_at.to_s
            ]
          end
        end
        render text: csv_str
      end
    end
  end

  def prev
    @attended_at = Date.parse(params[:attended_at])
    date = AttendanceRecord.where("attended_at < ?", @attended_at.strftime('%Y/%m/%d 0:00')).maximum(:attended_at)
    redirect_to administration_attendance_index_path(attended_at: date)
  end

  def next
    @attended_at = Date.parse(params[:attended_at])
    date = AttendanceRecord.where("attended_at > ?", @attended_at.strftime('%Y/%m/%d 23:59:59')).minimum(:attended_at)
    redirect_to administration_attendance_index_path(attended_at: date)
  end

  def destroy
    @record = AttendanceRecord.find(params[:id])
    @record.destroy
  end

  private

    def only_admins
      unless @logged_in.admin?(:manage_attendance)
        render text: t('only_admins'), layout: true, status: 401
        return false
      end
    end

end
