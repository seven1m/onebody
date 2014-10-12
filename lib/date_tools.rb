class Date
  def distance_to(end_date)
    years = end_date.year - year
    months = end_date.month - month
    days = end_date.day - day
    if days < 0
      days += 30
      months -= 1
    end
    if months < 0
      months += 12
      years -= 1
    end
    {years: years, months: months, days: days}
  end

  def self.parse_in_locale(string)
    begin
      strptime(string, Setting.get(:formats, :date))
    rescue ArgumentError
      begin
        parse(string) # fallback
      rescue ArgumentError
        nil
      end
    end
  end
end

class Time
  def self.parse_in_locale(string)
    begin
      strptime(string, Setting.get(:formats, :full_date_and_time))
    rescue ArgumentError
      begin
        strptime(string, Setting.get(:formats, :date))
      rescue ArgumentError
        begin
          parse(string) # fallback
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
