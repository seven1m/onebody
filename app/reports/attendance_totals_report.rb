class AttendanceTotalsReport < Dossier::Report

  def sql 
  	Group.select("name").joins(:attendance_records).select(:attended_at, "count(*) as
  att_count").references(:attendance_records).where("attended_at >= :fromdate and attended_at <= :thrudate",
  :fromdate).group("name", "attended_at").to_sql 
  end

  def fromdate
  	"2014-01-01"
  end

  def thrudate
  	"2014-08-20"
  end
end