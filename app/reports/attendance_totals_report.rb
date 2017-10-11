class AttendanceTotalsReport < ApplicationReport
  include ReportsHelper

  def headings
    [
      I18n.t('reports.reports.attendance_totals.columns.group'),
      I18n.t('reports.reports.attendance_totals.columns.attended_at'),
      I18n.t('reports.reports.attendance_totals.columns.count')
    ]
  end

  def sql
    Group
      .select(:name)
      .joins(:attendance_records)
      .select(:attended_at, 'count(*) as att_count')
      .references(:attendance_records)
      .where('attended_at >= ? and attended_at <= ?', from_date, thru_date)
      .group(:name, :attended_at)
      .order(:name)
      .to_sql
  end

  def from_date
    format_dateparam(options[:fromdate], (Date.current - 1.week))
  end

  def thru_date
    format_dateparam(options[:thrudate])
  end

  def format_attended_at(value)
    format_date(value)
  end
end
