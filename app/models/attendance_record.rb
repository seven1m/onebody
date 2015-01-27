class AttendanceRecord < ActiveRecord::Base
  belongs_to :person
  belongs_to :group
  belongs_to :site

  scope_by_site_id

  scope :on_date, -> d { where('date(attended_at) = date(?)', d) }

  validates :group, presence: true
  validates :attended_at, presence: true

  self.skip_time_zone_conversion_for_attributes = [:attended_at]

  def attended_at=(date)
    if date.respond_to?(:strftime)
      # strip time zone
      self[:attended_at] = date.strftime('%Y-%m-%dT%H:%M:%S')
    else
      self[:attended_at] = date
    end
  end

  def checkin_people
    Relationship.where('person_id = ? and other_name like ?', person_id, '%Check-in Person%').map(&:related).uniq
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
end
