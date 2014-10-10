module ReportsHelper

  def format_dateparam(date_in, *date_if_blank)
    date_if_blank = Date.current if date_if_blank.empty?
    Date.parse_in_locale(date_in.to_s) || Date.parse_in_locale(date_if_blank.to_s)
  end

  def format_date(value)
    value.to_s(:date) if value.is_a?(Time)
  end

end
