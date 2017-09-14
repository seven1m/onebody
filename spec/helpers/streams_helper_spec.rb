require 'rails_helper'

describe StreamsHelper, type: :helper do
  include ApplicationHelper

  describe 'stream_item_content' do
    before do
      @user = FactoryGirl.create(:person)
      @group = FactoryGirl.create(:group)
      @membership = @group.memberships.create!(person: @user)
    end

    it 'should be html_safe for messages' do
      @message = Message.create!(person: @user, group: @group, subject: 'Foo', body: 'Bar')
      @stream_item = StreamItem.last
      expect(@stream_item.streamable).to eq(@message)
      expect(stream_item_content(@stream_item)).to be_html_safe
    end

    it 'should be html_safe for pictures' do
      @album = Album.create!(owner: @user, name: 'Foo')
      @picture = @album.pictures.create!(person: @user, photo: File.open(Rails.root.join('spec/fixtures/files/image.jpg')))
      @stream_item = StreamItem.last
      expect(@stream_item.streamable).to eq(@album)
      expect(stream_item_content(@stream_item)).to be_html_safe
    end
  end
end
