class AttendanceRecord < ActiveRecord::Base
  belongs_to :person
  belongs_to :group
  belongs_to :site

  scope_by_site_id

  scope :on_date, -> d { where('date(attended_at) = date(?)', d) }

  validates_presence_of :group_id
  validates_presence_of :attended_at

  self.skip_time_zone_conversion_for_attributes = [:attended_at]

  def checkin_people
    Relationship.where('person_id = ? and other_name like ?', person_id, '%Check-in Person').map(&:related).uniq
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

  def self.daily_counts(limit, offset, date_strftime='%Y-%m-%d', only_show_date_for=nil)
    [].tap do |data|
      counts = connection.select_all("select count(date(attended_at)) as count, date(attended_at) as date from attendance_records where site_id=#{Site.current.id} group by date(attended_at) order by attended_at desc limit #{limit.to_i} offset #{offset.to_i};").group_by { |p| Date.parse(p['date'].strftime('%Y-%m-%d')) }
      ((Date.today-offset-limit+1)..(Date.today-offset)).each do |date|
        d = date.strftime(date_strftime)
        d = ' ' if only_show_date_for and date.strftime(only_show_date_for[0]) != only_show_date_for[1]
        count = counts[date] ? counts[date][0]['count'].to_i : 0
        data << [d, count]
      end
    end
  end
end
