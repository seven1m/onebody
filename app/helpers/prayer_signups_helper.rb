module PrayerSignupsHelper
  def range_of_hours(first, last)
    hours = []
    current = first
    begin
      hours << current
      current = DateTime.new(current.year, current.month, current.day, current.hour+1)
    end until current > last
    hours
  end
  def range_of_days(first, last)
    days = []
    current = Date.new(first.year, first.month, first.day)
    begin
      days << current
      current = Date.new(current.year, current.month, current.day+1)
    end until current > last
    days
  end
end
