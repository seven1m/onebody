class PrayerSignup < ActiveRecord::Base
  belongs_to :person
  acts_as_logger LogItem
end
