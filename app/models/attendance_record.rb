class AttendanceRecord < ActiveRecord::Base
  belongs_to :person
  belongs_to :group
  belongs_to :site
  belongs_to :checkin_time

  scope_by_site_id

  scope :on_date, -> d { where('date(attended_at) = date(?)', d) }

  validates_presence_of :group_id
  validates_presence_of :attended_at

  self.skip_time_zone_conversion_for_attributes = [:attended_at]

  def checkin_people
    Relationship.where('person_id = ? and other_name like ?', person_id, '%Check-in Person').map(&:related).uniq
  end

  def all_pickup_people
    checkin_people.map(&:name) + [can_pick_up]
  end

  def self.groups_for_date(attended_at)
    Group.where(
      "id in (select group_id from attendance_records where attended_at >= ? and attended_at <= ?)",
      attended_at.strftime('%Y-%m-%d 0:00'),
      attended_at.strftime('%Y-%m-%d 23:59:59')
    ).order('name')
  end

  def self.find_for_people_and_date(people_ids, date)
    where(
      "person_id in (?) and attended_at >= ? and attended_at <= ?",
      people_ids,
      date.strftime('%Y-%m-%d 0:00'),
      date.strftime('%Y-%m-%d 23:59:59')
    )
  end

  def self.check_in(person, times, barcode_id)
    times.map do |checkin_time_id, group_time_id|
      checkin_time = CheckinTime.find(checkin_time_id)
      attended_at = checkin_time.to_time
      where(person_id: person.id, attended_at: attended_at).delete_all
      if group_time_id
        group_time = GroupTime.find(group_time_id)
        group_time.group.attendance_records.create!(
          person_id:           person.id,
          attended_at:         attended_at,
          first_name:          person.first_name,
          last_name:           person.last_name,
          family_name:         person.family.name,
          age:                 person.age_group,
          can_pick_up:         person.can_pick_up,
          cannot_pick_up:      person.cannot_pick_up,
          medical_notes:       person.medical_notes,
          checkin_time_id:     group_time.checkin_time_id,
          print_nametag:       group_time.print_nametag?,
          print_extra_nametag: group_time.print_extra_nametag?,
          barcode_id:          barcode_id
        )
        ## record attendance for a person not in database (one at a time)
        #if person = params[:person] and @group
          #@group.attendance_records.create!(
            #attended_at:    @attended_at.strftime('%Y-%m-%d %H:%M:%S'),
            #first_name:     person['first_name'],
            #last_name:      person['last_name'],
            #age:            person['age']
          #)
        #end
      end
    end
  end
end
