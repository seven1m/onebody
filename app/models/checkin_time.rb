class CheckinTime < ActiveRecord::Base
  include Concerns::Reorder

  has_many :group_times, -> { order('group_times.sequence, group_times.id') }, dependent: :destroy
  has_many :groups, through: :group_times
  has_many :checkin_folders

  validates :campus, presence: true, exclusion: ['!']

  scope :recurring, -> { where(the_datetime: nil) }
  scope :today, ->(campus) { for_date(Time.now, campus) }
  scope :upcoming_singles, -> {
    where(
      'the_datetime is not null and the_datetime between :from and :to',
      from: 1.hour.ago.strftime('%Y-%m-%dT%H:%M:%S'),
      to:   4.hours.from_now.strftime('%Y-%m-%dT%H:%M:%S')
    )
  }
  scope :future_singles, -> {
    where(
      'the_datetime is not null and the_datetime >= ?',
      1.hour.ago.strftime('%Y-%m-%dT%H:%M:%S')
    )
  }

  scope_by_site_id

  def self.for_date(date, campus = nil)
    r = where(
      '((the_datetime >= ? and the_datetime <= ?) or weekday = ?)',
      date.beginning_of_day.strftime('%Y-%m-%dT%H:%M:%S'),
      date.end_of_day.strftime('%Y-%m-%dT%H:%M:%S'),
      date.wday
    )
    r.where!(campus: campus) if campus
    r
  end

  self.skip_time_zone_conversion_for_attributes = [:the_datetime]

  def all_group_times
    GroupTime
      .includes(:checkin_folder)
      .references(:checkin_folders)
      .order('coalesce(checkin_folders.sequence, group_times.sequence)')
      .where(
        'group_times.checkin_folder_id in (?) or group_times.checkin_time_id = ?',
        checkin_folder_ids,
        id
      )
  end

  validate do
    if weekday
      if time.nil?
        errors.add(:base, 'The time is not formatted correctly. Try something like "6:00 p.m."')
      end
      if the_datetime
        errors.add(:base, 'You cannot specify a specific date and time and a recurring time together.')
      end
    end
    if !weekday && !the_datetime
      errors.add(:base, 'You must specify either a recurring date and time or a specific date and time.')
    end
  end

  def time=(t)
    if t.present? && t = begin
                           Time.parse(t)
                         rescue
                           nil
                         end
      write_attribute(:time, t.strftime('%H%M').to_i)
    else
      write_attribute(:time, nil)
    end
  end

  def the_datetime=(t)
    self[:the_datetime] = t.present? ? Time.parse_in_locale(t).strftime('%Y-%m-%d %H:%M:%S') : nil
  end

  def to_s
    if the_datetime
      the_datetime.to_s(:full)
    elsif weekday
      "#{Date::DAYNAMES[weekday]} #{time_to_s}"
    else
      '' # invalid time
    end
  end

  def time_to_s
    if the_datetime
      the_datetime.to_s(:time)
    else
      Time.parse(time.to_s.sub(/(\d+)(\d{2})$/, '\1:\2')).to_s(:time)
    end
  end

  def to_time
    the_datetime || Time.parse(time_to_s)
  end

  def entries
    (checkin_folders.to_a + group_times.to_a).sort_by { |e| e.sequence.to_i }
  end

  def self.campuses
    distinct(:campus).pluck(:campus).sort
  end
end
