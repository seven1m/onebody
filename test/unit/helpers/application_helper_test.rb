require File.dirname(__FILE__) + '/../../test_helper'

class ApplicationHelperTest < ActionView::TestCase

  include WhiteListHelper

  context 'white_list_with_removal' do
    should 'remove style tags and their content' do
      assert_equal('before after', white_list_with_removal('before <style type="text/css">body { font-size: 12pt; }</style>after'))
    end
    should 'remove script tags and their content' do
      assert_equal('before after', white_list_with_removal('before <script type="text/javascript">alert("hi")</script>after'))
    end
    should 'remove other illegal tags' do
      assert_equal('before and after', white_list_with_removal('before <bad>and</bad> after'))
    end
    should 'allow safe tags' do
      assert_equal('before <strong>bold</strong> and <em>italic</em> after', white_list_with_removal('before <strong>bold</strong> and <em>italic</em> after'))
    end
    should 'be html_safe' do
      assert white_list_with_removal('<strong>safe</strong>').html_safe
    end
  end

  context 'error_messages_for' do
    setup do
      @Form = Struct.new(:object)
    end
    should 'return nothing if no errors' do
      form = @Form.new(people(:tim))
      assert error_messages_for(form).nil?
    end
    should 'be html_safe' do
      form = @Form.new(Album.create) # album doesn't have a name
      assert error_messages_for(form).html_safe?
    end
  end

  context 'render_page_content' do
    setup do
      system = Page.create!(:slug => 'system', :title => 'System', :body => 'system pages')
      sign_in_header = system.children.create!(:slug => 'sign_in_header', :title => 'Sign In Header', :body => 'safe<script>notsafe</script>')
    end
    should 'return sanitized content' do
      content = render_page_content('system/sign_in_header')
      assert_equal 'safe', content
    end
    should 'be html_safe' do
      assert render_page_content('system/sign_in_header').html_safe?
    end
    should 'return nil if no page found' do
      assert_nil render_page_content('system/nonexistent_page')
    end
  end

end
