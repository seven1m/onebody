require File.dirname(__FILE__) + '/../../test_helper'

class ApplicationHelperTest < ActionView::TestCase

  context 'sanitize_html' do
    should 'remove style tags and their content' do
      assert_equal('before after', sanitize_html('before <style type="text/css">body { font-size: 12pt; }</style>after'))
    end
    should 'remove script tags and their content' do
      assert_equal('before after', sanitize_html('before <script type="text/javascript">alert("hi")</script>after'))
    end
    should 'remove other illegal tags' do
      assert_equal('before and after', sanitize_html('before <bad>and</bad> after'))
    end
    should 'allow safe tags' do
      assert_equal('<p>before <strong>bold</strong> and <em>italic</em> after</p>', sanitize_html('<p>before <strong>bold</strong> and <em>italic</em> after</p>'))
    end
    should 'be html_safe' do
      assert sanitize_html('<strong>safe</strong>').html_safe?
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

  context 'date_field and date_field_tag' do
    should 'output a text field' do
      assert_equal '<input id="birthday" name="birthday" size="12" type="text" value="04/28/1981" />',
                   date_field_tag(:birthday, Date.new(1981, 4, 28))
      form_for(people(:tim)) do |form|
        assert_equal '<input id="person_birthday" name="person[birthday]" size="12" type="text" value="04/28/1981" />',
                     form.date_field(:birthday)
      end
    end
  end

  context 'phone_field' do
    should 'output a text field' do
      form_for(people(:tim)) do |form|
        assert_equal '<input id="person_mobile_phone" name="person[mobile_phone]" size="15" type="text" value="(918) 123-4567" />',
                     form.phone_field(:mobile_phone)
      end
    end
  end

end
