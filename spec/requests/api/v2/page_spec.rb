require_relative '../../../rails_helper'

describe 'Page API', type: :request do

  it 'should return a list of page items' do
    pages = FactoryGirl.create_list(:page, 10)

    get "/api/v2/pages"

    expect(response).to be_success
    # must account for the 6 system/help pages that always exist
    expect(json_data.length).to eq(16)
  end

  it 'should retrieve a specific page' do
    page = FactoryGirl.create(:page)

    get "/api/v2/pages/#{page.id}"

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(page.id)
  end

  it 'should retrieve the parent page if one exists' do
    parent = FactoryGirl.create(:page)
    page = FactoryGirl.create(:page, parent: parent)

    get "/api/v2/pages/#{page.id}/parent"

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(parent.id)
  end

  it 'should retrieve all child pages if any exist' do
    page = FactoryGirl.create(:page)
    FactoryGirl.create_list(:page, 5, parent: page)

    get "/api/v2/pages/#{page.id}/children"

    expect(response).to be_success
    expect(json_data.length).to eq(5)
    expect(json_data[0]['type']).to eq('pages')
  end
end