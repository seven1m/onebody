module ImportHelper
  def import_change_value(value)
    if value.is_a?(Date) || value.is_a?(Time)
      value.to_s(:date)
    elsif value.nil?
      ''
    else
      value.inspect
    end
  end
end
