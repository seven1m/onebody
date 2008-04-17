require File.dirname(__FILE__) + '/../test_helper'

class TwitterMessageTest < ActiveSupport::TestCase
  def test_unknown_twitter_account_causes_reply
    m = TwitterMessage.create(:twitter_screen_name => 'blabla')
    assert_equal 'Twitter screen name unknown.', m.errors.on(:twitter_screen_name)
  end
end
