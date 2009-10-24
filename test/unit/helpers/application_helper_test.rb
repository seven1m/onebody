require File.dirname(__FILE__) + '/../../test_helper'

class ApplicationHelperTest < ActionView::TestCase

  include WhiteListHelper

  context 'Whitelist' do
    should 'remove style tags and their content' do
      assert_equal('before after', white_list_with_removal('before <style type="text/css">body { font-size: 12pt; }</style>after'))
    end
    
    should 'remove script tags and their content' do
      assert_equal('before after', white_list_with_removal('before <script type="text/javascript">alert("hi")</script>after'))
    end
    
    should 'remove other illegal tags' do
      assert_equal('before and after', white_list_with_removal('before <bad>and</bad> after'))
    end
  end
  
end
