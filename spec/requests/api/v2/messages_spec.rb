require_relative '../../../rails_helper'

describe 'Messages API', type: :request do

  it 'should return a list of messages' do
    FactoryGirl.create_list(:message, 10)

    get '/api/v2/messages'

    expect(response).to be_success
    expect(json_data.length).to eq(10)
  end

  it 'should retrieve a specific message' do
    message = FactoryGirl.create(:message)

    get "/api/v2/messages/#{message.id}"

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(message.id)
    expect(json_attributes['body']).to eq(message.body)
  end

  it 'should retrieve the message group' do
    group = FactoryGirl.create(:group)
    message = FactoryGirl.create(:message, group: group)

    get "/api/v2/messages/#{message.id}/group"

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(group.id)
    expect(json_attributes['name']).to eq(group.name)
  end

  it 'should retrieve the message person' do
    person = FactoryGirl.create(:person)
    message = FactoryGirl.create(:message, person: person)

    get "/api/v2/messages/#{message.id}/person"

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(person.id)
    expect(json_attributes['first-name']).to eq(person.first_name)
  end

  it 'should retrieve who the message is to' do
    person = FactoryGirl.create(:person)
    message = FactoryGirl.create(:message, to: person)

    get "/api/v2/messages/#{message.id}/to"

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(person.id)
    expect(json_attributes['first-name']).to eq(person.first_name)
  end

  it 'should retrieve the parent message' do
    parent = FactoryGirl.create(:message)
    message = FactoryGirl.create(:message, parent: parent)

    get "/api/v2/messages/#{message.id}/parent"

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(parent.id)
  end

  it 'should retrieve all child messages' do
    message = FactoryGirl.create(:message)
    FactoryGirl.create_list(:message, 5, parent: message)

    get "/api/v2/messages/#{message.id}/children"

    expect(response).to be_success
    expect(json_data.length).to eq(5)
    expect(json_data[0]['type']).to eq('messages')
  end

  it 'should retrieve all attachments' do
    message = FactoryGirl.create(:message)
    FactoryGirl.create_list(:attachment, 3, message: message)

    get "/api/v2/messages/#{message.id}/attachments"

    expect(response).to be_success
    expect(json_data.length).to eq(3)
    expect(json_data[0]['type']).to eq('attachments')
  end


end