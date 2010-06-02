require File.dirname(__FILE__) + '/../test_helper'

class AlbumTest < ActiveSupport::TestCase

  should "have a cover picture" do
    @album = Album.forge
    Picture.forge(:album => @album)
    assert @album.cover
  end

  should "not have a cover if no photos are in the album" do
    @album = Album.forge
    assert_nil @album.cover
  end

end
