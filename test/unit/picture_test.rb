require File.dirname(__FILE__) + '/../test_helper'

class PictureTest < ActiveSupport::TestCase

  setup do
    @picture = Picture.forge
  end

  should 'rotate' do
    before = File.read(@picture.photo.path)
    assert @picture.rotate(90)
    after = File.read(@picture.photo.path)
    assert before != after
  end

end
