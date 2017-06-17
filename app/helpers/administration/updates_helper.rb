module Administration::UpdatesHelper
  def update_row(object, key, before, after)
    content_tag(:tr, class: 'update-row') do
      content_tag(:td, class: 'strong') do
        object.class.human_attribute_name(key)
      end +
        content_tag(:td, format_update_value(key, before)) +
        content_tag(:td, format_update_value(key, after))
    end
  end

  def format_update_value(key, value)
    if [Date, Time, DateTime].include?(value.class)
      value.to_s(:date)
    elsif key =~ /phone|fax/
      format_phone(value)
    else
      value
    end
  end
end
