module CustomFieldsHelper
  def show_custom_fields?
    CustomField.any?
  end
end
