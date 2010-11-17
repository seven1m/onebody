require File.dirname(__FILE__) + '/../test_helper'

class DateTest < ActiveSupport::TestCase

  should 'be formatted properly' do
    assert_equal '01/02/2013', Time.parse('2013-01-02').to_s(:date)
    assert_equal '01/02/2013', Date.new(2013, 1, 2).to_s(:date)
    assert_equal '01/02/2013 01:01 PM', Time.parse('2013-01-02 13:01').to_s
    assert_equal '01/02/2013 01:01 PM', DateTime.parse('2013-01-02 13:01').to_s
  end

end
