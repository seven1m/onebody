require_relative '../../../test_helper'

class Administration::DashboardsHelperTest < ActionView::TestCase

  context 'display_metric' do
    setup do
      @alerts = []
    end
    should 'output its content' do
      html = display_metric false do
        concat 'content'
      end
      assert_equal '<p>content</p>', html
    end
    should 'output its content inside the specified tag' do
      html = display_metric false, :content_tag => 'div' do
        concat 'content'
      end
      assert_equal '<div>content</div>', html
    end
    should 'add to alerts if alert=true' do
      html = display_metric true do
        concat 'content'
      end
      assert_equal '<p>content</p>', html
      assert_equal ['content'], @alerts
    end
  end

end
