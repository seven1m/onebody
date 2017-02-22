require_relative '../../../rails_helper'

describe 'Comments API', type: :request do
  let!(:application) { FactoryGirl.create(:oauth_application) }
  let!(:token)       { FactoryGirl.create(:oauth_access_token, application: application) }

  it 'should return a list of comments' do
    FactoryGirl.create_list(:comment, 10)

    get "/api/v2/comments", :access_token => token.token

    expect(response).to be_success
    expect(json_data.length).to eq(10)
  end

  it 'should retrieve a specific comment' do
    comment = FactoryGirl.create(:comment)

    get "/api/v2/comments/#{comment.id}", :access_token => token.token

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(comment.id)
  end

  it 'should retrieve the person of a comment' do
    person = FactoryGirl.create(:person)
    comment = FactoryGirl.create(:comment, person: person)

    get "/api/v2/comments/#{comment.id}/person", :access_token => token.token

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(person.id)
    expect(json_data['type']).to eq('people')
  end

end