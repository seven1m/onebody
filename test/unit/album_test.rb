require_relative '../test_helper'

class AlbumTest < ActiveSupport::TestCase

  setup do
    @album = FactoryGirl.create(:album)
  end

  context '#cover' do
    context 'album has a picture marked as cover' do
      setup do
        @other = @album.pictures.create!
        @cover = @album.pictures.create!(cover: true)
      end

      should 'returns the picture marked cover' do
        assert_equal @cover, @album.cover
      end
    end

    context 'album has no pictures marked as cover' do
      setup do
        @first = @album.pictures.create!
        sleep 0.1
        @second = @album.pictures.create!
      end

      should 'returns the first picture ordered by creation' do
        assert_equal @first, @album.cover
      end
    end

    context 'has has no pictures' do
      should 'returns nil' do
        assert_nil @album.cover
      end
    end
  end


end
