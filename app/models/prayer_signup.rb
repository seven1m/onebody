class PrayerSignup < ActiveRecord::Base
  belongs_to :person
  belongs_to :site

  scope_by_site_id

  acts_as_logger LogItem

  validates_uniqueness_of :start, :scope => [:site_id, :person_id]
  validates_presence_of :start

  self.skip_time_zone_conversion_for_attributes = [:start]

  class << self
    def deliver_reminders
      signups = find :all, :conditions => "start >= now()"
      signups = signups.group_by &:person
      signups.each do |person, times|
        if person.email.to_s.any?
          puts person.name
          Notifier.prayer_reminder(person, times).deliver
        end
      end
      nil
    end
  end
end
