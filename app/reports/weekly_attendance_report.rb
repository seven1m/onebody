class WeeklyAttendanceReport < Dossier::Report
  include ReportsHelper

  def initialize(*args)
    super
    @group = Group.find(options[:group_id]) if options[:group_id].present?
  end

  def formatted_title
    I18n.t(
      @group ? 'title_for_group' : 'title',
      scope: 'reports.reports.weekly_attendance',
      group: @group.try(:name)
    )
  end

  def sql
    return none unless @group
    @group.attendance_records
          .select(:person_id, :first_name, :last_name)
          .where('attended_at between :fromdate and :thrudate')
          .order(:first_name, :last_name)
          .to_sql
  end

  set_callback :execute, :after, :insert_non_attending

  # this is sort of hacky, but an improvement on doing a large UNION in the sql
  # I wish Dossier allowed easier munging of the results
  def insert_non_attending
    if @group
      rows = query_results.rows
      rows.each { |p| p << I18n.t('reports.reports.weekly_attendance.attended.yes') }
      @group.people.each do |person|
        next if query_results.rows.detect { |r| r[0] == person.id }
        rows << [person.id,
                 person.first_name,
                 person.last_name,
                 I18n.t('reports.reports.weekly_attendance.attended.no')]
      end
      rows.sort_by! { |p| [p[1], p[2]] }
    end
  end

  def fromdate
    format_dateparam(options[:fromdate], (Date.current - 1.week))
  end

  def thrudate
    format_dateparam(options[:thrudate])
  end

  def format_attended_at(value)
    format_date(value)
  end

  def group_id
    options[:group_id]
  end

  def none
    'select null from attendance_records where 1=0'
  end
end
