# == Schema Information
# Schema version: 20080715223033
#
# Table name: twitter_messages
#
#  id                  :integer       not null, primary key
#  twitter_screen_name :integer       
#  person_id           :integer       
#  message             :string(140)   
#  reply               :string(140)   
#  created_at          :datetime      
#  updated_at          :datetime      
#

class TwitterMessage < ActiveRecord::Base
  belongs_to :site
  acts_as_scoped_globally 'site_id', "(Site.current ? Site.current.id : 'site-not-set')"

  MAX_MESSAGES_PER_MINUTE = 200
  
  belongs_to :person
  
  validates_presence_of :twitter_screen_name
  
  def validate
    if TwitterMessage.count('*', :conditions => ['created_at >= ?', 1.minutes.ago]) > MAX_MESSAGES_PER_MINUTE
      errors.add_to_base('Too many messages per minute.')
    end
    unless self.person
      errors.add(:twitter_screen_name, 'Twitter screen name unknown.')
    end
  end
    
  def twitter_screen_name=(screen_name)
    write_attribute :twitter_screen_name, screen_name
    self.person = Person.find_by_twitter_account(screen_name)
  end
  
  def build_reply
    raise 'No message' unless self.message.to_s.strip.any?
    if self.message =~ /^\s*(lookup|phone|mobile|home|work|address)\s*(.+)/
      lookup_name = sql_lcase(sql_concat('first_name', "' '", 'last_name'))
      if found = Person.find(:first, :conditions => ["#{lookup_name} like ?", $2.downcase + '%']) \
        and self.person.can_see?(found)
        case $1
        when 'lookup', 'phone', 'mobile'
          if found.share_mobile_phone_with(self.person) and found.mobile_phone.to_i > 0
            self.reply = "#{found.mobile_phone} - #{found.name}"
          else
            self.reply = "Mobile number not available for #{found.name}"
          end
        when 'home'
          if found.home_phone.to_i > 0
            self.reply = "#{found.home_phone} - #{found.name}"
          else
            self.reply = "Home number not available for #{found.name}"
          end
        when 'work'
          if found.share_work_phone_with(self.person) and found.work_phone.to_i > 0
            self.reply = "#{found.work_phone} - #{found.name}"
          else
            self.reply = "Work number not available for #{found.name}"
          end
        when 'address'
          if found.share_address_with(self.person) and found.address1.to_s.any? and found.city.to_s.any? and found.state.to_s.any?
            self.reply = "#{found.family.mapable_address} - #{found.name}"
          else
            self.reply = "Address not available for #{found.name}"
          end
        end
      else
        self.reply = 'No one with that name could be found.'
      end
    else
      self.reply = 'Send "mobile John Doe" or "address John Doe" or similar.'
    end
  end
end
