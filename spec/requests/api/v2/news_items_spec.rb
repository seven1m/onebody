require_relative '../../../rails_helper'

describe 'News Items API', type: :request do
  let!(:application) { FactoryGirl.create(:oauth_application) }
  let!(:token)       { FactoryGirl.create(:oauth_access_token, application: application) }

  it 'should return a list of news items' do
    news = FactoryGirl.create_list(:news_item, 10)

    get "/api/v2/news-items", :access_token => token.token

    expect(response).to be_success
    expect(json_data.length).to eq(10)
  end

  it 'should retrieve a specific news item' do
    news = FactoryGirl.create(:news_item)

    get "/api/v2/news-items/#{news.id}", :access_token => token.token

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(news.id)
  end

  it 'should retrieve the person from a news item' do
    person = FactoryGirl.create(:person)
    news = FactoryGirl.create(:news_item, person: person)

    get "/api/v2/news-items/#{news.id}/person", :access_token => token.token

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(person.id)
  end
end