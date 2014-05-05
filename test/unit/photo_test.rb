require_relative '../test_helper'

class PhotoTest < ActiveSupport::TestCase

  should 'save a photo for a person' do
    @person = FactoryGirl.create(:person)
    @person.photo = File.open(Rails.root.join('test/fixtures/files/image.jpg'))
    @person.save
    @person.reload
    assert @person.photo.exists?
    assert_match %r{#{@person.id}/original/#{@person.photo_fingerprint}\.jpg}, @person.photo.url
    assert_match %r{#{@person.id}/original/#{@person.photo_fingerprint}\.jpg}, @person.photo.path
  end

end
