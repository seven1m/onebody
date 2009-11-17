module Administration::DashboardsHelper

  def day_word(date)
    today = Date.today
    d = date.to_date
    if d > today
      date.to_s(:date)
    elsif d == today
      'today'
    elsif d == today - 1
      'yesterday'
    elsif d > today - 7
      date.strftime('%A')
    else
      date.to_s(:date)
    end
  end

end