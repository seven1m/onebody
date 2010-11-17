require File.dirname(__FILE__) + '/abstract_unit'

class TaggingTest < ActiveSupport::TestCase
  def test_tag
    assert_equal tags(:good), taggings(:jonathan_sky_good).tag
  end
  
  def test_taggable
    assert_equal posts(:jonathan_sky), taggings(:jonathan_sky_good).taggable
  end
end
