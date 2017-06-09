class Administration::AttendanceController < ApplicationController
  before_filter :only_admins

  VALID_SORT_COLS = %w(
    attendance_records.last_name
    attendance_records.first_name
    groups.name
    attendance_records.attended_at
    attendance_records.created_at
    people.child
  ).freeze

  # TODO: refactor
  def index
    @attended_at = params[:attended_at] ? Date.parse_in_locale(params[:attended_at]) : Date.current
    @groups = AttendanceRecord.groups_for_date(@attended_at)
    @rel = AttendanceRecord.where('attended_at >= ? and attended_at <= ?', @attended_at.strftime('%Y-%m-%d 0:00'), @attended_at.strftime('%Y-%m-%d 23:59:59'))
    @rel.includes!(:person, :group)
    @rel.references!(:person, :group)
    if params[:group_id].to_i > 0
      @group = Group.find(params[:group_id])
      @rel.where!(group_id: @group.id)
      params[:sort] ||= 'attendance_records.last_name,attendance_records.first_name'
    end
    if params[:ids]
      @groups = Group.find(params[:ids])
      @rel.where!(group_id: @groups.map(&:id))
      params[:sort] ||= 'attendance_records.last_name,attendance_records.first_name'
    end
    if params[:person_name]
      @rel.where!("concat(attendance_records.first_name, ' ', attendance_records.last_name) like ?", "%#{params[:person_name]}%")
    end
    unless params[:sort].to_s.split(',').all? { |col| VALID_SORT_COLS.include?(col) }
      params[:sort] = 'groups.name'
    end
    @rel.order!(params[:sort])
    respond_to do |format|
      format.html do
        @records = @rel.paginate(page: params[:page], per_page: 100)
        @record_count = @records.total_entries
      end
      format.csv do
        CSV.generate(csv_str = '') do |csv|
          csv << %w(group_name group_id group_link_code first_name last_name person_id person_legacy_id class_time recorded_time)
          @rel.each do |record|
            csv << [
              record.group.try(:name),
              record.group.try(:id),
              record.group.try(:link_code),
              record.first_name,
              record.last_name,
              record.person_id,
              record.person.try(:legacy_id),
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
    date = AttendanceRecord.where('attended_at < ?', @attended_at.strftime('%Y/%m/%d 0:00')).maximum(:attended_at)
    redirect_to administration_attendance_index_path(attended_at: date)
  end

  def next
    @attended_at = Date.parse(params[:attended_at])
    date = AttendanceRecord.where('attended_at > ?', @attended_at.strftime('%Y/%m/%d 23:59:59')).minimum(:attended_at)
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
      false
    end
  end
end
