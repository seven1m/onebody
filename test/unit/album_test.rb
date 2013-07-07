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

  context '#group' do
    context 'album owner is a person' do
      setup do
        @person = FactoryGirl.create(:person)
        @album.update_attributes!(owner: @person)
      end

      should 'return nil' do
        assert_nil @album.group
      end
    end

    context 'album owner is a group' do
      setup do
        @group = FactoryGirl.create(:group)
        @album.update_attributes!(owner: @group)
      end

      should 'return the group' do
        assert_equal @group, @album.group
      end
    end
  end

  context '#person' do
    context 'album owner is a person' do
      setup do
        @person = FactoryGirl.create(:person)
        @album.update_attributes!(owner: @person)
      end

      should 'return the person' do
        assert_equal @person, @album.person
      end
    end

    context 'album owner is a group' do
      setup do
        @group = FactoryGirl.create(:group)
        @album.update_attributes!(owner: @group)
      end

      should 'return nil' do
        assert_nil @album.person
      end
    end
  end
end
