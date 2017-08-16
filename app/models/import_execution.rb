class ImportExecution
  include Concerns::Import::Attributes

  def initialize(import)
    @import = import
    @created_family_ids = {}
    @created_family_names = {}
  end

  def execute
    return unless ready?
    index = 0
    @import.rows.where(status: ImportRow.statuses[row_status_before]).find_each do |row|
      @import.reload if index % 100 == 0 # make sure import didn't get deleted
      index += 1
      row.reset_statuses
      if (person = row.match_person)
        update_existing_person(row, person)
      else
        create_new_person(row)
      end
      save_row(row)
    end
    @import.update_attributes(status: status_after, completed_at: set_completed_at? ? Time.now : nil)
  end

  private

  def set_completed_at?
    true
  end

  def status_before
    'active'
  end

  def row_status_before
    'previewed'
  end

  def status_after
    'complete'
  end

  def ready?
    @import.status == status_before
  end

  def save_row(row)
    row.person.save
    row.family.save
    record_changes(row)
    row.status = :imported
    row.save!
  end

  def update_existing_person(row, person)
    set_person_attributes(row, person)
    person.dont_stream = true
    if (family = match_family(row))
      person.family = family
      update_existing_family(row, family)
    elsif person.family && id_for_family(row).blank? && legacy_id_for_family(row).blank?
      update_existing_family(row, person.family)
    else
      create_new_family(row, person)
    end
    row.updated_person = (person.valid? && person.changed?)
    row.created_family = row.updated_family = false if person.invalid?
    record_errors(row, person)
    row.person = person
  end

  def set_person_attributes(row, person)
    attributes = attributes_for_person(row)
    person.dont_mark_email_changed = true
    if @import.overwrite_changed_emails?
      person.email_changed = false
      person.attributes = attributes
    else
      person.email_changed = false if attributes['email'] == person.email
      person.attributes = attributes
      person.restore_attributes([:email]) if person.email_changed?
    end
    set_custom_field_values(person, attributes['fields'])
  end

  def create_new_person(row)
    person = Person.new(attributes_for_person(row))
    person.dont_stream = true
    if (person.family = match_family(row))
      update_existing_family(row, person.family)
    else
      create_new_family(row, person)
    end
    row.created_person = person.valid?
    row.created_family = row.updated_family = false unless row.created_person
    record_errors(row, person)
    row.person = person
  end

  def update_existing_family(row, family)
    attrs_before = family.attributes.dup
    family.attributes = attributes_for_family(row)
    update_family_last_name(row, family)
    row.updated_family = (family.attributes != attrs_before) && family.valid?
    row.family = family
  end

  def create_new_family(row, person)
    attrs = attributes_for_family(row)
    person.family = Family.new(attrs)
    update_family_last_name(row, person.family)
    if (row.created_family = person.family.valid?)
      if (id = id_for_family(row))
        @created_family_ids[id] = person.family
      else
        @created_family_names[attrs['name']] = person.family
      end
    end
    row.family = person.family
  end

  def record_changes(row, changes_method = :previous_changes)
    row.attribute_changes ||= {}
    unless row.person.new_record?
      row.attribute_changes[:person] = row.person.send(changes_method).reject { |k| k == 'updated_at' }
      fields = CustomField.all.index_by(&:id)
      row.person.field_changes.each do |id, change|
        row.attribute_changes[:person][fields[id].slug] = change
      end
    end
    unless row.family.new_record?
      row.attribute_changes[:family] = row.family.send(changes_method).reject { |k| k == 'updated_at' }
    end
  end

  def update_family_last_name(row, family)
    return if row.import_attributes_as_hash(real_attributes: true)['family_last_name']
    family.last_name = family.name.split.last if family.name.present?
  end

  def match_family(row)
    row.match_family ||
      ((id = id_for_family(row)) && @created_family_ids[id]) ||
      ((name = attributes_for_family(row)['name']) && @created_family_names[name])
  end

  def record_errors(row, person)
    family_errors = person.errors.delete(:family)
    hash = person.errors.to_h
    hash[:family] = person.family.errors.to_h if family_errors
    hash.delete(:"custom_field_values.value")
    hash.merge!(custom_field_errors(person))
    row.attribute_errors = hash
    row.errored = hash.any?
  end

  def custom_field_errors(person)
    person.custom_field_values.each_with_object({}) do |field_value, hash|
      next if field_value.errors.none?
      hash[field_value.field.slug] = field_value.errors[:value].join('; ')
    end
  end

  def set_custom_field_values(person, attrs)
    @options_lookup ||= CustomField.select_field_options_lookup_by_label
    attrs = attrs.dup
    attrs.each do |field_id, value|
      next unless (options = @options_lookup[field_id])
      attrs[field_id] = if (id = options[value.downcase])
                          id
                        else
                          Concerns::Person::Fields::LabelLookupFailure.new(value)
                        end
    end
    person.fields = attrs
  end
end
