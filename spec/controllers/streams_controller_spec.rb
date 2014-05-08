require_relative '../spec_helper'

describe StreamsController do
  render_views

  before do
    @person = FactoryGirl.create(:person)
    @friend = FactoryGirl.create(:person)
  end

  it 'should show a stream' do
    get :show, nil, {logged_in_id: @person.id}
    expect(response).to be_success
  end

  it 'should show stream items and comments with commenter thumbnail' do
    @pic = FactoryGirl.create(:picture, :with_file, person: @person)
    @pic.comments.create(person: @friend)
    get :show, nil, {logged_in_id: @person.id}
    expect(response).to be_success
  end

  it 'should show selection of picture when commenting on album with more than one picture' do
    @pic = FactoryGirl.create(:picture, :with_file, person: @person)
    @pic2 = FactoryGirl.create(:picture, :with_file, person: @person, album: @pic.album)
    get :show, nil, {logged_in_id: @person.id}
    expect(response).to be_success
    assert_select 'body', /which picture/i
  end

  it 'should group like items from a single person' do
    @n1 = FactoryGirl.create(:note, person: @person)
    sleep 1 # so the creation time will sort properly
    @n2 = FactoryGirl.create(:note, person: @person)
    get :show, nil, {logged_in_id: @person.id}
    expect(response).to be_success
    @stream_item = StreamItem.where(streamable_type: "Note", streamable_id: @n1.id).first
    assert_select "#stream-item-group#{@stream_item.id}", 1
  end

  it 'should not ever group news items' do
    @n1 = FactoryGirl.create(:news_item, person: @person)
    sleep 1 # so the creation time will sort properly
    @n2 = FactoryGirl.create(:news_item, person: @person)
    get :show, nil, {logged_in_id: @person.id}
    expect(response).to be_success
    @stream_item = StreamItem.where(streamable_type: "NewsItem", streamable_id: @n1.id).first
    assert_select "#stream-item-group#{@stream_item.id}", 0
  end

end
