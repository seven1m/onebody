module NotifierHelper

  def format_changed_attribute(attribute, value)
    if value.is_a?(DateTime) or value.is_a?(Time)
      value.to_s(:date)
    elsif attribute =~ /_phone$/ or attribute == 'fax'
      number_to_phone(value, :area_code => true).to_s
    else
      value.to_s
    end
  end
  
end
