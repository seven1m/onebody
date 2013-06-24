require_relative '../test_helper'

class StreamsControllerTest < ActionController::TestCase

  def setup
    @person = Person.forge
    @friend = Person.forge
  end

  should 'show a stream' do
    get :show, nil, {:logged_in_id => @person.id}
    assert_response :success
  end

  should 'show stream items and comments with commenter thumbnail' do
    @pic = @person.forge(:pictures)
    @pic.comments.create(:person => @friend)
    get :show, nil, {:logged_in_id => @person.id}
    assert_response :success
  end

  should 'show selection of picture when commenting on album with more than one picture' do
    @pic = @person.forge(:pictures)
    @pic2 = @person.forge(:pictures, :album => @pic.album)
    get :show, nil, {:logged_in_id => @person.id}
    assert_response :success
    assert_select 'body', /which picture/i
  end

  should 'group like items from a single person' do
    @n1 = @person.forge(:notes)
    sleep 1 # so the creation time will sort properly
    @n2 = @person.forge(:notes)
    get :show, nil, {:logged_in_id => @person.id}
    assert_response :success
    @stream_item = StreamItem.find_by_streamable_type_and_streamable_id('Note', @n1.id)
    assert_select "#stream-item-group#{@stream_item.id}", 1
  end

  should 'not ever group news items' do
    @n1 = NewsItem.forge(:person => @person)
    sleep 1 # so the creation time will sort properly
    @n2 = NewsItem.forge(:person => @person)
    get :show, nil, {:logged_in_id => @person.id}
    assert_response :success
    @stream_item = StreamItem.find_by_streamable_type_and_streamable_id('NewsItem', @n1.id)
    assert_select "#stream-item-group#{@stream_item.id}", 0
  end

end
