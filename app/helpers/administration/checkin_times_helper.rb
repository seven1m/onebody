module Administration::CheckinTimesHelper
  
  def checkin_time(time)
    if time.the_datetime
      time.the_datetime.to_s
    else
      d = Date::DAYNAMES[time.weekday]
      t = Time.parse(time.time.to_s.sub(/(\d+)(\d{2})$/, '\1:\2')).to_s(:time)
      "#{d} #{t}"
    end
  end
  
end
