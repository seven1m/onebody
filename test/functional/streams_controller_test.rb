require File.dirname(__FILE__) + '/../test_helper'

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

end
