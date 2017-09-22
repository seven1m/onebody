class AttendanceBatch
  attr_reader :attended_at

  def initialize(group, attended_at)
    @group = group
    @attended_at = time_without_zone(parse(attended_at))
  end

  def parse(time)
    return if time.blank?
    time = ensure_date(time)
    Time.parse_in_locale(time) || Date.parse_in_locale(time)
  end

  def ensure_date(time)
    return time if time =~ %r{\d\d?[-/]\d\d?[-/]\d\d?}
    Date.current.strftime('%Y-%m-%d ') + time
  end

  def time_without_zone(time)
    return if time.blank?
    ActiveSupport::TimeZone['UTC'].parse(time.strftime('%Y-%m-%dT%H:%M:%S'))
  end

  def remove(ids)
    Array(ids).map do |id|
      next unless (person = Person.undeleted.where(id: id).first)
      clear(person)
    end.compact
  end

  def update(ids)
    Array(ids).map do |id|
      next unless (person = Person.undeleted.where(id: id).first)
      clear(person)
      create(person)
    end.compact
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
