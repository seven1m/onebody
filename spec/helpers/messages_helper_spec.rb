require 'rails_helper'

describe MessagesHelper, type: :helper do
  include ApplicationHelper

  describe 'render_message_html_body' do
    before do
      @user = FactoryGirl.create(:person)
      @message = Message.create!(person: @user, subject: 'Foo', body: 'Bar')
    end

    it 'should be html_safe' do
      expect(render_message_html_body(@message.body)).to be_html_safe
    end
  end
end
