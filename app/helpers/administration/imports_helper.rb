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
    Import.match_strategies.map do |key, val|
      [
        I18n.t(key, scope: 'administration.imports.match_strategies'),
        key
      ]
    end
  end

  def import_mapping_option_tags(from, to)
    options_for_select(
      @import.mappable_attributes,
      import_mapping_selection(from, to)
    )
  end

  def import_mapping_selection(from, to)
    to || previous_import_mapping(from) || from
  end

  def previous_import_mapping(from)
    previous_import.mappings[from]
  end

  def previous_import
    Import.where.not(id: @import.id).order(:created_at).last
  end

  def import_row_record_status(row, model)
    if row.send("created_#{model}?")
      I18n.t('administration.imports.created')
    elsif row.send("updated_#{model}?")
      I18n.t('administration.imports.updated')
    else
      I18n.t('administration.imports.unchanged')
    end
  end
end
