require File.dirname(__FILE__) + '/../test_helper'

class TwitterMessageTest < ActiveSupport::TestCase
  def test_unknown_twitter_account_causes_reply
    m = TwitterMessage.create!(:twitter_message_id => '1234', :twitter_screen_name => 'blabla', :message => 'test')
    m.build_reply
    m.save
    assert_match /I don't recognize your Twitter account./, m.reply
  end
end
