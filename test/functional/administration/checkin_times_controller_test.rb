require File.dirname(__FILE__) + '/../../test_helper'

class Administration::CheckinTimesControllerTest < ActionController::TestCase

  setup { Setting.set(1, 'Features', 'Checkin Modules', true) }
  
  should "create a new recurring checkin time" do
    post :create, {:checkin_time => {:weekday => 0, :time => '9:00'}}, {:logged_in_id => people(:tim)}
    assert_response :redirect
    assert_redirected_to :action => 'index'
    assert_equal 1, CheckinTime.count
  end
  
  should "create a new single (non-recurring) checkin time" do
    post :create, {:checkin_time => {:the_datetime => '12/31/2010 6:00 p.m.'}}, {:logged_in_id => people(:tim)}
    assert_response :redirect
    assert_redirected_to :action => 'index'
    assert_equal 1, CheckinTime.count
  end
  
  should "accept different date and time formats" do
    post :create, {:checkin_time => {:the_datetime => '12/29/2010 6:00 p.m.'}}, {:logged_in_id => people(:tim)}
    assert_equal({}, flash)
    assert_not_nil CheckinTime.find_by_the_datetime('2010-12-29 18:00')
    
    post :create, {:checkin_time => {:the_datetime => '30-12-2010 18:00'}}, {:logged_in_id => people(:tim)}
    assert_equal({}, flash)
    assert_not_nil CheckinTime.find_by_the_datetime('2010-12-30 18:00')
    
    post :create, {:checkin_time => {:the_datetime => '2010/12/31 6pm'}}, {:logged_in_id => people(:tim)}
    assert_equal({}, flash)
    assert_not_nil CheckinTime.find_by_the_datetime('2010-12-31 18:00')
    
    post :create, {:checkin_time => {:weekday => 0, :time => '9am'}}, {:logged_in_id => people(:tim)}
    assert_equal({}, flash)
    assert_not_nil CheckinTime.find_by_weekday_and_time(0, 900)
    
    post :create, {:checkin_time => {:weekday => 0, :time => '10:30 a.m.'}}, {:logged_in_id => people(:tim)}
    assert_equal({}, flash)
    assert_not_nil CheckinTime.find_by_weekday_and_time(0, 1030)
    
    post :create, {:checkin_time => {:weekday => 0, :time => '18:00'}}, {:logged_in_id => people(:tim)}
    assert_equal({}, flash)
    assert_not_nil CheckinTime.find_by_weekday_and_time(0, 1800)
    
    assert_equal 6, CheckinTime.count
  end
  
  should "delete a checkin time" do
    @time = CheckinTime.create(:weekday => 0, :time => '9:00')
    assert @time.valid?
    post :destroy, {:id => @time.id}, {:logged_in_id => people(:tim)}
    assert_response :redirect
    assert_redirected_to :action => 'index'
    assert_equal 0, CheckinTime.count
  end
  
end
