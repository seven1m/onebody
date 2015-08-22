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
    to || guess_import_mapping(from)
  end

  def guess_import_mapping(from)
    @import.mappable_attributes.detect do |attr|
      attr.downcase.gsub(/_/, ' ').index(
        from.downcase.gsub(/_/, ' ')
      )
    end
  end
end
