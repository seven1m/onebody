class ImportExecution
  def initialize(import)
    @import = import
  end

  def execute
    return unless @import.previewed?
    @import.update_attributes(status: 'active')
    @import.rows.each do |row|
      attributes = row.import_attributes_as_hash(real_attributes: true)
      if (person = row.match_person)
        person.attributes = attributes
        if person.changed?
          if person.save
            row.status = :updated
            row.error_reasons = nil
          else
            row.status = :errored
            row.error_reasons = person.errors.values.join('; ')[0...255]
          end
        else
          row.status = :unchanged
          row.error_reasons = nil
        end
      else
        person = Person.new(attributes)
        if person.save
          row.status = :created
          row.error_reasons = nil
        else
          row.status = :errored
          row.error_reasons = row.errors.values.join('; ')[0...255]
        end
      end
      row.save
    end
    @import.update_attributes(
      status: 'complete',
      completed_at: Time.now
    )
  end
end
