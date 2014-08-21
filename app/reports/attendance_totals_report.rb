class AttendanceTotalsReport < Dossier::Report

  def sql
 	  Group.select("name").joins(:attendance_records).select(:attended_at, "count(*) as
  att_count").references(:attendance_records).where("attended_at >= :fromdate and attended_at <= :thrudate").group("name", "attended_at").to_sql
  end

  def fromdate
    Date.strptime(options[:fromdate], Setting.get(:formats, :date)) unless options[:fromdate].nil?
  end

  def thrudate
    Date.strptime(options[:thrudate], Setting.get(:formats, :date)) unless options[:thrudate].nil?
  end

  def format_attended_at(value)
    value.strftime(Setting.get(:formats, :date))
  end

end
