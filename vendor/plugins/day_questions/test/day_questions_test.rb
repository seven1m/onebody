require File.dirname(__FILE__) + '/test_helper'

class DayQuestionsTest < Test::Unit::TestCase
  def test_yesterday
    [:to_time, :to_date].each do |type|
      assert !2.days.ago.yesterday?
      assert !(1.day.ago.beginning_of_day - 1.second).send(type).yesterday?
      assert (Time.now.beginning_of_day - 1.second).send(type).yesterday?
      assert (Time.now - 1.day).send(type).yesterday?
      assert (Time.now - 1.day).beginning_of_day.send(type).yesterday?
      assert !Time.now.beginning_of_day.send(type).yesterday?
      assert !Time.now.send(type).yesterday?
    end
  end
  
  def test_today
    [:to_time, :to_date].each do |type|
      assert !1.day.ago.send(type).today?
      assert !(Time.now.beginning_of_day - 1.second).send(type).today?
      assert Time.now.beginning_of_day.send(type).today?
      assert Time.now.send(type).today?
      assert (1.day.from_now.beginning_of_day - 1.second).send(type).today?
      assert !1.day.from_now.beginning_of_day.send(type).today?
      assert !1.day.from_now.send(type).today?
    end
  end
  
  def test_tomorrow
    [:to_time, :to_date].each do |type|
      assert !Time.now.send(type).tomorrow?
      assert !(1.day.from_now.beginning_of_day - 1.second).send(type).tomorrow?
      assert 1.day.from_now.beginning_of_day.send(type).tomorrow?
      assert 1.day.from_now.send(type).tomorrow?
      assert (2.days.from_now.beginning_of_day - 1.second).send(type).tomorrow?
      assert !2.days.from_now.beginning_of_day.send(type).tomorrow?
      assert !2.days.from_now.send(type).tomorrow?
    end
  end
  
  def test_around_today
    [:to_time, :to_date].each do |type|
      assert !2.days.ago.send(type).around_today?
      assert 1.day.ago.send(type).around_today?
      assert Time.now.send(type).around_today?
      assert 1.day.from_now.send(type).around_today?
      assert !2.days.from_now.send(type).around_today?
    end
  end
  
  def test_human_day
    assert_equal 'Today', Time.now.human_day
    assert_equal 'Yesterday', 1.day.ago.human_day
    assert_equal 'Tomorrow', 1.day.from_now.human_day
    assert_equal '12/31', Time.parse('12/31/2006').human_day
  end
  
  def test_human_day_with_custom_value
    assert_equal 'on Sun', Time.parse('12/31/2006').human_day('on %a')
  end
end
