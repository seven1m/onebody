class PrayerSignup < ActiveRecord::Base
  belongs_to :person
  belongs_to :site

  scope_by_site_id

  scope :upcoming, -> { where('start >= now()') }

  validates_uniqueness_of :start, scope: [:site_id, :person_id]
  validates_presence_of :start

  self.skip_time_zone_conversion_for_attributes = [:start]

  class << self
    def deliver_reminders
      upcoming.group_by(&:person).each do |person, times|
        if person.email.to_s.any?
          puts person.name
          Notifier.prayer_reminder(person, times).deliver
        end
      end
      nil
    end
  end
end
