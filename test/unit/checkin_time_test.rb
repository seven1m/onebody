require File.dirname(__FILE__) + '/../test_helper'

class Administration::CheckinTimeTest < ActiveSupport::TestCase
  
  should "return all checkin times for today" do
    assert_equal 0, CheckinTime.today.length
    CheckinTime.create(:weekday => Date.today.wday, :time => '10:00 a.m.')
    assert_equal 1, CheckinTime.today.length
  end
  
end
