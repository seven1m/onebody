require_relative '../test_helper'

class AlbumTest < ActiveSupport::TestCase

  should "have a cover picture" do
    @album = FactoryGirl.create(:album)
    FactoryGirl.create(:picture, :album => @album)
    assert @album.cover
  end

  should "not have a cover if no photos are in the album" do
    @album = FactoryGirl.create(:album)
    assert_nil @album.cover
  end

end
