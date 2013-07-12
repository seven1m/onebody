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

  context '#cover=' do
    context 'album has a picture marked as cover' do
      setup do
        @pic1 = @album.pictures.create!(cover: true)
        @pic2 = @album.pictures.create!
        @album.update_attributes!(cover: @pic2)
      end

      should 'unset existing as cover' do
        assert !@pic1.reload.cover
      end

      should 'set new cover' do
        assert @pic2.reload.cover
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

  context 'remove_owner = true' do
    context 'owner is a person' do
      setup do
        Person.logged_in = @user = FactoryGirl.create(:person)
        @album.owner = FactoryGirl.create(:person)
      end

      context 'user is not an admin' do
        setup do
          @album.remove_owner = true
        end

        should 'not clear owner' do
          assert_not_nil @album.owner
        end
      end

      context 'user is an admin with manage_pictures privilege' do
        setup do
          @user.update_attributes(admin: Admin.create!(manage_pictures: true))
          @album.remove_owner = true
        end

        should 'clear owner' do
          assert_nil @album.owner
        end

        should 'set album to public' do
          assert @album.is_public?
        end
      end
    end
  end
end
