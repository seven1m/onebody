require_relative '../test_helper'

class PictureTest < ActiveSupport::TestCase

  setup do
    @picture = FactoryGirl.create(:picture)
  end

  should 'rotate' do
    before = File.read(@picture.photo.path)
    assert @picture.rotate(90)
    after = File.read(@picture.photo.path)
    assert before != after
  end

end
