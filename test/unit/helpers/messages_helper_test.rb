require File.dirname(__FILE__) + '/../../test_helper'

class MessagesHelperTest < ActionView::TestCase
  include ApplicationHelper

  context 'render_message_html_body' do
    setup do
      @message = Message.create!(:person_id => people(:tim), :subject => 'Foo', :body => 'Bar')
    end
    should 'be html_safe' do
      assert render_message_html_body(@message.body).html_safe?
    end
    should "remove sensitive links"
    should "hide contact details"
    should "automatically add links for urls"
  end
end
