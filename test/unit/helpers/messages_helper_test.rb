require_relative '../../test_helper'

class MessagesHelperTest < ActionView::TestCase
  include ApplicationHelper

  context 'render_message_html_body' do
    setup do
      @user = FactoryGirl.create(:person)
      @message = Message.create!(person: @user, subject: 'Foo', body: 'Bar')
    end

    should 'be html_safe' do
      assert render_message_html_body(@message.body).html_safe?
    end
  end
end
