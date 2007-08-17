require File.dirname(__FILE__) + '/../test_helper'

class FeedTest < Test::Unit::TestCase
  fixtures :feeds

  def test_truth
    assert true
  end

  # not ready yet
  def dont_test_get_spec_and_name
    {
      :morgan => ['atom', 'The Morgan Family'],
      :mpov   => ['rss', 'MPOV'],
      :rss09  => ['rss', 'RSS 0.9 Test'],
      :rss10  => ['rss', 'RSS 1.0 Test'],
      :rss20  => ['rss', 'RSS 2.0 Test'],
      :atom03 => ['atom', 'Atom 0.3 Test'],
      :atom10 => ['atom', 'Atom 1.0 Test']
    }.each do |feed, expected|
      spec, name = expected
      feeds(feed).fetch
      assert_equal spec, feeds(feed).reload.spec
      assert_equal name, feeds(feed).name
    end
  end
end
