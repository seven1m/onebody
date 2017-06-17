module NotifierHelper
  def format_changed_attribute(attribute, value)
    if value.is_a?(DateTime) || value.is_a?(Time)
      value.to_s(:date)
    elsif attribute =~ /_phone$/ || attribute == 'fax'
      ApplicationHelper.format_phone(value, attribute =~ /mobile/).to_s
    else
      value.to_s
    end
  end
end
