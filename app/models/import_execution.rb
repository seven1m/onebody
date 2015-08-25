class ImportExecution
  include Concerns::Import::Attributes

  def initialize(import)
    @import = import
  end

  def execute
    return unless @import.previewed?
    @import.update_attributes(status: 'active')
    import_rows
    @import.update_attributes(
      status: 'complete',
      completed_at: Time.now
    )
  end

  private

  def import_rows
    @import.rows.each do |row|
      if (person = row.match_person)
        update_person(person, row)
      else
        create_person(row)
      end
      row.save
    end
  end

  def update_person(person, row)
    row.person = person
    person.attributes = attributes_for_person(row)
    person.family.attributes = attributes_for_family(row)
    if person.changed? || person.family.changed?
      if person.save && person.family.save
        row.status = :updated
        row.error_reasons = nil
      else
        row.status = :errored
        row.error_reasons = errors_as_string(person)
      end
    else
      row.status = :unchanged
      row.error_reasons = nil
    end
  end

  def create_person(row)
    person = Person.new(attributes_for_person(row))
    person.family = Family.new(attributes_for_family(row))
    person.family.last_name ||= person.last_name
    if person.save
      row.status = :created
      row.error_reasons = nil
      row.person = person
    else
      row.status = :errored
      row.error_reasons = errors_as_string(person)
    end
  end
end
