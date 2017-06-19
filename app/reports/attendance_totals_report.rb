class AttendanceTotalsReport < Dossier::Report
  include ReportsHelper

  def sql
    Group
      .select(:name)
      .joins(:attendance_records)
      .select(:attended_at, 'count(*) as att_count')
      .references(:attendance_records)
      .where('attended_at >= :fromdate and attended_at <= :thrudate')
      .group(:name, :attended_at)
      .order(:name)
      .to_sql
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
end
