require_relative '../test_helper'

class FeedTest < ActiveSupport::TestCase

  def setup
    @person = Person.forge
  end

  context 'URL Transformation' do

    should "not transform the url for Twitter" do
      url = 'http://twitter.com/statuses/user_timeline.atom?screen_name=seven1m'
      @feed = Feed.forge(:person => @person, :url => url)
      assert_equal url, @feed.url
    end

    should "transform the url for Facebook" do
      url = 'http://facebook.com/notifications.php?blabla'
      @feed = Feed.forge(:person => @person, :url => url)
      assert_equal 'http://facebook.com/status.php?blabla', @feed.url
    end

  end

end
