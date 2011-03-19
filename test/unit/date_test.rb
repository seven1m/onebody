require File.dirname(__FILE__) + '/../test_helper'

class DateTest < ActiveSupport::TestCase

  should 'parse date with year first' do
    assert_equal 'Jan 02, 2013', Time.parse('2013-01-02').strftime('%b %d, %Y')
    assert_equal 'Jan 02, 2013', Date.parse('2013-01-02').strftime('%b %d, %Y')
    assert_equal 'Jan 02, 2013 01:01 PM', Time.parse('2013-01-02 13:01').strftime('%b %d, %Y %I:%M %p')
    assert_equal 'Jan 02, 2013 01:01 PM', DateTime.parse('2013-01-02 13:01').strftime('%b %d, %Y %I:%M %p')
  end

  should 'parse american dates' do
    Setting.set(1, 'Formats', 'Date', '%m/%d/%Y')
    assert_equal 'Jan 02, 2013', Date.parse_in_locale('01/02/2013').strftime('%b %d, %Y')
    assert_equal 'Jan 02, 2013', Date.parse_in_locale('1/2/2013').strftime('%b %d, %Y')
  end

  should 'parse european dates' do
    Setting.set(1, 'Formats', 'Date', '%d/%m/%Y')
    assert_equal 'Jan 02, 2013', Date.parse_in_locale('02/01/2013').strftime('%b %d, %Y')
    assert_equal 'Jan 02, 2013', Date.parse_in_locale('2/1/2013').strftime('%b %d, %Y')
    #Setting.set(1, 'Formats', 'Date', '%m/%d/%Y') # put this back
  end

end
