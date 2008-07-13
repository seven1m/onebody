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
  
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"
  
  acts_as_logger LogItem

  class << self
    def deliver_reminders
      signups = find :all, :conditions => "start >= now()"
      signups = signups.group_by &:person
      signups.each do |person, times|
        if person.email.to_s.any?
          puts person.name
          Notifier.deliver_prayer_reminder(person, times)
        end
      end
      nil
    end
  end
end
