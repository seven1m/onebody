require_relative '../../test_helper'

class StreamsHelperTest < ActionView::TestCase
  include ApplicationHelper

  context 'stream_item_content' do
    setup do
      @user = FactoryGirl.create(:person)
      @group = FactoryGirl.create(:group)
      @membership = @group.memberships.create!(person: @user)
    end

    should 'be html_safe for messages' do
      @message = Message.create!(person: @user, group: @group, subject: 'Foo', body: 'Bar')
      @stream_item = StreamItem.last
      assert_equal @message, @stream_item.streamable
      assert stream_item_content(@stream_item).html_safe?
    end

    should 'be html_safe for pictures' do
      @album = Album.create!(owner: @user, name: 'Foo')
      @picture = @album.pictures.create!(person: @user, photo: File.open(Rails.root.join('test/fixtures/files/image.jpg')))
      @stream_item = StreamItem.last
      assert_equal @album, @stream_item.streamable
      assert stream_item_content(@stream_item).html_safe?
    end
  end
end
