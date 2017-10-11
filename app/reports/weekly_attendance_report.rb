class WeeklyAttendanceReport < ApplicationReport
  include ReportsHelper

  def initialize(*args)
    super
    @group = Group.find(options[:group_id]) if options[:group_id].present?
  end

  def headings
    [
      I18n.t('reports.reports.weekly_attendance.columns.person_id'),
      I18n.t('reports.reports.weekly_attendance.columns.first_name'),
      I18n.t('reports.reports.weekly_attendance.columns.last_name'),
      I18n.t('reports.reports.weekly_attendance.columns.attended')
    ]
  end

  def formatted_title
    I18n.t(
      @group ? 'title_for_group' : 'title',
      scope: 'reports.reports.weekly_attendance',
      group: @group.try(:name)
    )
  end

  def sql
    return AttendanceRecord.none unless @group
    @group.attendance_records
          .select(:person_id, :first_name, :last_name)
          .where('attended_at between ? and ?', from_date, thru_date)
          .order(:first_name, :last_name)
          .to_sql
  end

  def execute
    return [] unless @group
    rows = super
    found = {}
    rows.each do |row|
      found[row[0]] = true
      row << I18n.t('reports.reports.weekly_attendance.attended.yes')
    end
    @group.people.each do |person|
      next if found[person.id]
      rows << [
        person.id,
        person.first_name,
        person.last_name,
        I18n.t('reports.reports.weekly_attendance.attended.no')
      ]
    end
    rows.sort_by! { |p| [p[1], p[2]] }
  end

  def from_date
    format_dateparam(options[:from_date], (Date.current - 1.week))
  end

  def thru_date
    format_dateparam(options[:thru_date])
  end

  def format_attended_at(value)
    format_date(value)
  end

  def group_id
    options[:group_id]
  end
end
