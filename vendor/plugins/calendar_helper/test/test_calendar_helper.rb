require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "/../lib/calendar_helper")

class CalendarHelperTest < Test::Unit::TestCase

  include CalendarHelper
  
  
  def test_simple
    assert_match %r{August}, calendar_with_defaults
  end


  def test_required_fields
    # Year and month are required
    assert_raises(ArgumentError) {
      calendar
    }
    assert_raises(ArgumentError) {
      calendar :year => 1
    }
    assert_raises(ArgumentError) {
      calendar :month => 1
    }    
  end

  def test_default_css_classes
    # :other_month_class is not implemented yet
    { :table_class => "calendar", 
      :month_name_class => "monthName", 
      :day_name_class => "dayName", 
      :day_class => "day" }.each do |key, value|
      assert_correct_css_class_for_default value
    end
  end


  def test_custom_css_classes
    # Uses the key name as the CSS class name
    # :other_month_class is not implemented yet
    [:table_class, :month_name_class, :day_name_class, :day_class].each do |key|
      assert_correct_css_class_for_key key.to_s, key
    end
  end

  
  def test_abbrev
    assert_match %r{>Mon<}, calendar_with_defaults(:abbrev => (0..2))
    assert_match %r{>M<}, calendar_with_defaults(:abbrev => (0..0))
    assert_match %r{>Monday<}, calendar_with_defaults(:abbrev => (0..-1))
  end


  def test_block
    # Even days are special
    assert_match %r{class="special_day">2<}, calendar(:year => 2006, :month => 8) { |d|
      if d.mday % 2 == 0
        [d.mday, {:class => 'special_day'}]
      end
    }
  end


  def test_first_day_of_week
    assert_match %r{<tr class="dayName">\s*<th>Sun}, calendar_with_defaults
    assert_match %r{<tr class="dayName">\s*<th>Mon}, calendar_with_defaults(:first_day_of_week => 1)
  end

private


  def assert_correct_css_class_for_key(css_class, key)
    assert_match %r{class="#{css_class}"}, calendar_with_defaults(key => css_class)
  end

  def assert_correct_css_class_for_default(css_class)
    assert_match %r{class="#{css_class}"}, calendar_with_defaults
  end

  def calendar_with_defaults(options={})
    options = { :year => 2006, :month => 8 }.merge options
    calendar options
  end

end
