require File.dirname(__FILE__) + '/../../test_helper'

class ApplicationHelperTest < ActionView::TestCase

  context 'Whitelist' do
    should 'remove style tags and their content' do
      assert_equal('beforeafter', white_list_with_removal('before<style type="text/css">body { font-size: 12pt; }</style>after'))
    end
  end
  
end
