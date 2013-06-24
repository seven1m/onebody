require_relative '../test_helper'

class StreamsControllerTest < ActionController::TestCase

  def setup
    @person = FactoryGirl.create(:person)
    @friend = FactoryGirl.create(:person)
  end

  should 'show a stream' do
    get :show, nil, {logged_in_id: @person.id}
    assert_response :success
  end

  should 'show stream items and comments with commenter thumbnail' do
    @pic = FactoryGirl.create(:picture, person: @person)
    @pic.comments.create(person: @friend)
    get :show, nil, {logged_in_id: @person.id}
    assert_response :success
  end

  should 'show selection of picture when commenting on album with more than one picture' do
    @pic = FactoryGirl.create(:picture, person: @person)
    @pic2 = FactoryGirl.create(:picture, person: @person, album: @pic.album)
    get :show, nil, {logged_in_id: @person.id}
    assert_response :success
    assert_select 'body', /which picture/i
  end

  should 'group like items from a single person' do
    @n1 = FactoryGirl.create(:note, person: @person)
    sleep 1 # so the creation time will sort properly
    @n2 = FactoryGirl.create(:note, person: @person)
    get :show, nil, {logged_in_id: @person.id}
    assert_response :success
    @stream_item = StreamItem.find_by_streamable_type_and_streamable_id('Note', @n1.id)
    assert_select "#stream-item-group#{@stream_item.id}", 1
  end

  should 'not ever group news items' do
    @n1 = FactoryGirl.create(:news_item, person: @person)
    sleep 1 # so the creation time will sort properly
    @n2 = FactoryGirl.create(:news_item, person: @person)
    get :show, nil, {logged_in_id: @person.id}
    assert_response :success
    @stream_item = StreamItem.find_by_streamable_type_and_streamable_id('NewsItem', @n1.id)
    assert_select "#stream-item-group#{@stream_item.id}", 0
  end

end
