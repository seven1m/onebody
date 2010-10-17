require File.dirname(__FILE__) + '/abstract_unit'

class TagsHelperTest < ActiveSupport::TestCase
  include TagsHelper
  
  def test_tag_cloud
    cloud_elements = []
    
    tag_cloud Post.tag_counts, %w(css1 css2 css3 css4) do |tag, css_class|
      cloud_elements << [tag, css_class]
    end
    
    assert cloud_elements.include?([tags(:good), "css2"])
    assert cloud_elements.include?([tags(:bad), "css1"])
    assert cloud_elements.include?([tags(:nature), "css4"])
    assert cloud_elements.include?([tags(:question), "css1"])
    assert_equal 4, cloud_elements.size
  end
  
  def test_tag_cloud_when_no_tags
    tag_cloud SpecialPost.tag_counts, %w(css1) do
      assert false, "tag_cloud should not yield"
    end
  end
end
