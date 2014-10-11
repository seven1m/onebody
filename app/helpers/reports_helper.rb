module ReportsHelper

  def format_dateparam(date_in, *date_if_blank)
    date_if_blank = Date.current if date_if_blank.empty?
    Date.parse_in_locale(date_in.to_s) || Date.parse_in_locale(date_if_blank.to_s)
  end

  def format_date(value)
    value.to_s(:date) if value.is_a?(Time)
  end

  def report_date_field(form, name, value)
    content_tag(:div, class: 'input-group') do
      content_tag(:div, class: 'input-group-btn') do
        content_tag(:button, type: 'button', class: 'btn btn-info date-picker-btn') do
          icon('fa fa-calendar')
        end
      end +
      form.date_field(name, class: 'form-control')
    end
  end

end
