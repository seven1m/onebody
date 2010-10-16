# == Schema Information
# Schema version: 20080709134559
#
# Table name: prayer_signups
#
#  id         :integer       not null, primary key
#  person_id  :integer
#  start      :datetime
#  created_at :datetime
#  reminded   :boolean
#  other      :string(100)
#  site_id    :integer
#

class PrayerSignup < ActiveRecord::Base
  belongs_to :person
  belongs_to :site

  scope_by_site_id

  acts_as_logger LogItem

  validates_uniqueness_of :start, :scope => 'person_id'
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
