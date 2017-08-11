module CustomFieldsHelper
  def show_custom_fields?
    CustomField.any?
  end

  def custom_field_select_options(field)
    options_for_select(
      [nil] + field.options.map { |o| [o.label, o.id] },
      @person && @person.fields[field.id]
    )
  end
end
