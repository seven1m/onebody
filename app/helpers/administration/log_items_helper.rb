module Administration::LogItemsHelper
  
  def log_item_path(log_item)
    send(log_item.loggable_type.underscore + '_path', log_item.loggable_id)
  end
  
  def log_item_change_value(value)
    if value.is_a?(Time)
      value.in_time_zone
    elsif value.respond_to?(:name)
      value.name
    else
      value
    end
  end
  
end