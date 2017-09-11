class AttendanceRecord < ApplicationRecord
  belongs_to :person, optional: true
  belongs_to :group
  belongs_to :checkin_time, optional: true
  belongs_to :checkin_label, foreign_key: :label_id, optional: true

  scope_by_site_id

  scope :on_date, ->(d) { where('date(attended_at) = date(?)', d) }

  validates :group, presence: true
  validates :attended_at, presence: true

  self.skip_time_zone_conversion_for_attributes = [:attended_at]

  def attended_at=(date)
    self[:attended_at] = if date.respond_to?(:strftime)
                           # strip time zone
                           date.strftime('%Y-%m-%dT%H:%M:%S')
                         else
                           date
                         end
  end

  def checkin_people
    Relationship.where('person_id = ? and other_name like ?', person_id, '%Check-in Person%').map(&:related).uniq
  end

  def all_pickup_people
    checkin_people.map(&:name) + [can_pick_up]
  end

  def as_json(*args)
    super.merge(symbol: symbol)
  end

  def symbol
    ''.tap do |syms|
      syms << '+' if medical_notes.present?
      syms << '!' if cannot_pick_up.present?
    end
  end

  def self.groups_for_date(attended_at)
    Group.where(
      'id in (select group_id from attendance_records where attended_at >= ? and attended_at <= ?)',
      attended_at.strftime('%Y-%m-%d 0:00'),
      attended_at.strftime('%Y-%m-%d 23:59:59')
    ).order('name')
  end

  def self.find_for_people_and_date(people_ids, date)
    where(
      'person_id in (?) and attended_at >= ? and attended_at <= ?',
      people_ids,
      date.strftime('%Y-%m-%d 0:00'),
      date.strftime('%Y-%m-%d 23:59:59')
    )
  end

  def self.check_in(person_id, times, barcode_id)
    if person_id.to_s =~ /\A\d+\z/
      person = Person.find(person_id)
    else
      (first_name, last_name) = person_id.split(nil, 2)
      person = OpenStruct.new(first_name: first_name, last_name: last_name)
    end
    times.map do |checkin_time_id, group_time_hash|
      checkin_time = CheckinTime.find(checkin_time_id)
      attended_at = checkin_time.to_time
      if person.id
        where(person_id: person.id, attended_at: attended_at.strftime('%Y-%m-%d %H:%M:%S')).delete_all
      end
      next unless group_time_hash && group_time_hash['id']
      group_time = GroupTime.find(group_time_hash['id'])
      group_time.group.attendance_records.create!(
        person_id:           person.id,
        attended_at:         attended_at,
        first_name:          person.first_name,
        last_name:           person.last_name,
        family_name:         person.family.try(:name),
        age:                 person.age_group,
        can_pick_up:         person.can_pick_up,
        cannot_pick_up:      person.cannot_pick_up,
        medical_notes:       person.medical_notes,
        checkin_time_id:     group_time.checkin_time_id || group_time.checkin_folder.try(:checkin_time_id),
        label_id:            group_time.label_id,
        print_extra_nametag: group_time.print_extra_nametag?,
        barcode_id:          barcode_id
      )
    end
  end

  def self.labels_for(records)
    [].tap do |labels|
      records.compact.each do |record|
        next unless record.checkin_label && labels.empty?
        json = record.as_json.merge(label_id: record.label_id)
        labels << json
        labels << json if record.print_extra_nametag? && labels.length < 2
      end
    end
  end
end
