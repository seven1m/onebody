require 'rails_helper'

describe 'Photo' do
  it 'should save a photo for a person' do
    @person = FactoryGirl.create(:person)
    @person.photo = File.open(Rails.root.join('spec/fixtures/files/image.jpg'))
    @person.save
    @person.reload
    expect(@person.photo).to be_exists
    expect(@person.photo.url).to match(/#{@person.id}\/original\/#{@person.photo_fingerprint}\.jpg/)
    expect(@person.photo.path).to match(/#{@person.id}\/original\/#{@person.photo_fingerprint}\.jpg/)
  end
end
