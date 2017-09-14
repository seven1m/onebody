require 'rails_helper'

describe PhotosController, type: :controller do
  before do
    @family = FactoryGirl.create(:family)
    @person = FactoryGirl.create(:person)
  end

  it 'should update a photo' do
    post :update,
         params: { family_id: @person.family.id, photo: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true) },
         session: { logged_in_id: @person.id }
    expect(response).to be_redirect
  end

  it 'should not update a photo unless user can edit the object' do
    post :update,
         params: { family_id: @family.id, photo: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true) },
         session: { logged_in_id: @person.id }
    expect(response).to be_error
  end

  it 'should not update a photo with invalid content type' do
    post :update,
         params: { family_id: @person.family.id, photo: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.bmp'), 'image/bmp', true) },
         session: { logged_in_id: @person.id }
    expect(response).to be_redirect
    expect(flash[:warning]).to be
  end

  it 'should delete a photo' do
    post :destroy,
         params: { family_id: @person.family.id },
         session: { logged_in_id: @person.id }
    expect(response).to be_redirect
  end

  it 'should not delete a photo unless user can edit the object' do
    post :destroy,
         params: { family_id: @family.id },
         session: { logged_in_id: @person.id }
    expect(response).to be_error
  end
end
