class PrayerController < ApplicationController
  def event
    @first = DateTime.new(2007, 1, 21, 0, 0) # midnight on Jan 21, 2007
    @last = DateTime.new(2007, 1, 27, 23, 0) # 11pm on Jan 28, 2007
    @signups = PrayerSignup.find :all, :conditions => ['when >= ? and when <= ?', @first, @last], :order => 'when'
  end
end
