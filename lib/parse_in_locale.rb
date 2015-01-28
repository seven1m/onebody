class Date
  def self.parse_in_locale(string)
    string = string.to_s
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
    string = string.to_s
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
