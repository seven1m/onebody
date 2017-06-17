module Administration::ImportsHelper
  def import_status_icon(import, status)
    if import.status_at_least?(status)
      icon('fa fa-check-square text-green') +
        ' Complete'
    else
      icon('fa fa-square text-yellow') +
        ' Pending'
    end
  end

  def import_path(import)
    administration_import_path(import)
  end

  def import_match_strategies
    Import.match_strategies.map do |key, _val|
      [
        I18n.t(key, scope: 'administration.imports.match_strategies'),
        key
      ]
    end
  end

  def import_mapping_option_tags(from, to)
    options_for_select(@import.mappable_attributes, to || from)
  end

  def import_row_record_status(row, model)
    if row.send("created_#{model}?")
      I18n.t('administration.imports.created')
    elsif row.send("updated_#{model}?")
      content_tag :span, title: row.attribute_changes.inspect do
        I18n.t('administration.imports.updated')
      end
    else
      I18n.t('administration.imports.unchanged')
    end
  end

  def import_link_to(model)
    return if model.nil?
    return if model.deleted?
    link_to(model.id, model)
  end

  def import_row_errors(row)
    errors = row.attribute_errors.dup
    return [] if errors.blank?
    family_errors = errors.delete('family') || {}
    attrs = row.import_attributes_as_hash(real_attributes: true)
    errors.map do |attr, error|
      { name: attr, value: attrs[attr], message: error }
    end +
      family_errors.map do |attr, error|
        name = "family_#{attr}"
        { name: name, value: attrs[name], message: error }
      end
  end
end
