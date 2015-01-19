class AttendanceBatch

  attr_reader :attended_at

  def initialize(group, attended_at)
    @group = group
    @attended_at = parse(attended_at)
  end

  def parse(date)
    Time.parse_in_locale(date) ||
    Date.parse_in_locale(date)
  end

  def update(ids)
    Array(ids).map do |id|
      if person = Person.undeleted.where(id: id).first
        clear(person)
        create(person)
      end
    end.compact
  end

  def clear_all_for_date
    @group.attendance_records_for_date(@attended_at).delete_all
  end

  def clear(person)
    AttendanceRecord.where(
      person_id: person.id,
      attended_at: @attended_at
    ).delete_all
  end

  def create(person)
    @group.attendance_records.create!(
      person_id:      person.id,
      attended_at:    @attended_at,
      first_name:     person.first_name,
      last_name:      person.last_name,
      family_name:    person.family.name,
      age:            person.age_group,
      can_pick_up:    person.can_pick_up,
      cannot_pick_up: person.cannot_pick_up,
      medical_notes:  person.medical_notes
    )
  end

  def create_unlinked(person)
    @group.attendance_records.create!(
      attended_at:    @attended_at,
      first_name:     person['first_name'],
      last_name:      person['last_name'],
      age:            person['age']
    )
  end

end
