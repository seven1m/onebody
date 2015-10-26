require_relative '../../../rails_helper'

describe 'News Items API', type: :request do

  it 'should return a list of news items' do
    news = FactoryGirl.create_list(:news_item, 10)

    get "/api/v2/news-items"

    expect(response).to be_success
    expect(json_data.length).to eq(10)
  end

  it 'should retrieve a specific news item' do
    news = FactoryGirl.create(:news_item)

    get "/api/v2/news-items/#{news.id}"

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(news.id)
  end

  it 'should retrieve the person from a news item' do
    person = FactoryGirl.create(:person)
    news = FactoryGirl.create(:news_item, person: person)

    get "/api/v2/news-items/#{news.id}/person"

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(person.id)
  end
end