module Administration::LogItemsHelper
  
  def log_item_path(log_item)
    if log_item.loggable_type == 'Picture'
      picture_path(log_item.loggable)
    else
      send(log_item.loggable_type.underscore + '_path', log_item.loggable_id)
    end
  end
  
  def log_item_change_value(log_item, attribute, value)
    model = Kernel.const_get(log_item.loggable_type)
    if value.is_a?(Time)
      if model.skip_time_zone_conversion_for_attributes.include?(attribute.to_sym)
        value
      else
        value.in_time_zone
      end
    elsif value.respond_to?(:name)
      value.name
    elsif value.nil?
      'nil'
    else
      value
    end
  end
  
end