class AttendanceTotalsReport < Dossier::Report

  def sql
    Group.select(:name)
         .joins(:attendance_records)
         .select(:attended_at, 'count(*) as att_count')
         .references(:attendance_records)
         .where('attended_at >= :fromdate and attended_at <= :thrudate')
         .group(:name, :attended_at)
         .to_sql
  end

  def fromdate
    Date.parse_in_locale(options[:fromdate].to_s) || (Date.current - 1.week)
  end

  def thrudate
    Date.parse_in_locale(options[:thrudate].to_s) || Date.current
  end

  def format_attended_at(value)
    value.to_s(:date) if value.is_a?(Time)
  end

end
