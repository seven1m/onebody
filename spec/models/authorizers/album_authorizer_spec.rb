require_relative '../../rails_helper'

describe AlbumAuthorizer do
  before do
    @user = FactoryGirl.create(:person)
    @album = FactoryGirl.create(:album)
  end

  it 'should not read album' do
    expect(@user).to_not be_able_to(:read, @album)
  end

  it 'should not update album' do
    expect(@user).to_not be_able_to(:update, @album)
  end

  it 'should not delete album' do
    expect(@user).to_not be_able_to(:delete, @album)
  end

  context 'new album' do
    before do
      @album = Album.new
    end

    it 'should create album' do
      expect(@user).to be_able_to(:create, @album)
    end

    context 'belonging to a group' do
      before do
        @group = FactoryGirl.create(:group)
        @album.owner = @group
      end

      it 'should not create album' do
        expect(@user).to_not be_able_to(:create, @album)
      end

      context 'user is group member' do
        before do
          @group.memberships.create!(person: @user)
        end

        it 'should create album' do
          expect(@user).to be_able_to(:create, @album)
        end

        context 'group has pictures disabled' do
          before do
            @group.update_attributes!(pictures: false)
          end

          it 'should not create album' do
            expect(@user).to_not be_able_to(:create, @album)
          end
        end
      end

      context 'user is admin with manage_pictures and manage_groups privileges' do
        before do
          @user.update_attributes!(admin: Admin.create(manage_pictures: true, manage_groups: true))
        end

        it 'should create album' do
          expect(@user).to be_able_to(:create, @album)
        end

        context 'group has pictures disabled' do
          before do
            @group.update_attributes!(pictures: false)
          end

          it 'should not create album' do
            expect(@user).to_not be_able_to(:create, @album)
          end
        end
      end
    end
  end

  context 'album is marked public' do
    before do
      @album.update_attributes!(is_public: true)
    end

    it 'should read album' do
      expect(@user).to be_able_to(:read, @album)
    end

    it 'should list album' do
      expect(AlbumAuthorizer.readable_by(@user)).to include(@album)
    end
  end

  context 'owned by user' do
    before do
      @album.update_attributes!(owner: @user)
    end

    it 'should read album' do
      expect(@user).to be_able_to(:read, @album)
    end

    it 'should update album' do
      expect(@user).to be_able_to(:update, @album)
    end

    it 'should delete album' do
      expect(@user).to be_able_to(:delete, @album)
    end

    it 'should list album' do
      expect(AlbumAuthorizer.readable_by(@user)).to include(@album)
    end
  end

  context 'owned by a friend' do
    before do
      @friend = FactoryGirl.create(:person)
      Friendship.create!(person: @user, friend: @friend)
      @album.update_attributes!(owner: @friend)
    end

    it 'should read album' do
      expect(@user).to be_able_to(:read, @album)
    end

    it 'should list album' do
      expect(AlbumAuthorizer.readable_by(@user)).to include(@album)
    end
  end

  context 'album in a group' do
    before do
      @group = FactoryGirl.create(:group)
      @album.update_attributes!(owner: @group)
    end

    it 'should not read album' do
      expect(@user).to_not be_able_to(:read, @album)
    end

    it 'should not update album' do
      expect(@user).to_not be_able_to(:update, @album)
    end

    it 'should not delete album' do
      expect(@user).to_not be_able_to(:delete, @album)
    end

    it 'should not list album' do
      expect(AlbumAuthorizer.readable_by(@user)).to_not include(@album)
    end

    context 'user is group member' do
      before do
        @group.memberships.create(person: @user)
      end

      it 'should read album' do
        expect(@user).to be_able_to(:read, @album)
      end

      it 'should list album' do
        expect(AlbumAuthorizer.readable_by(@user)).to include(@album)
      end

      it 'should not update album' do
        expect(@user).to_not be_able_to(:update, @album)
      end

      it 'should not delete album' do
        expect(@user).to_not be_able_to(:delete, @album)
      end
    end

    context 'user is group admin' do
      before do
        @group.memberships.create(person: @user, admin: true)
      end

      it 'should read album' do
        expect(@user).to be_able_to(:read, @album)
      end

      it 'should list album' do
        expect(AlbumAuthorizer.readable_by(@user)).to include(@album)
      end

      it 'should update album' do
        expect(@user).to be_able_to(:update, @album)
      end

      it 'should delete album' do
        expect(@user).to be_able_to(:delete, @album)
      end
    end
  end

  context 'user is admin with manage_pictures privilege' do
    before do
      @user.update_attributes!(admin: Admin.create!(manage_pictures: true))
    end

    it 'should read album' do
      expect(@user).to be_able_to(:read, @album)
    end

    it 'should list album' do
      expect(AlbumAuthorizer.readable_by(@user)).to include(@album)
    end

    it 'should update album' do
      expect(@user).to be_able_to(:update, @album)
    end

    it 'should delete album' do
      expect(@user).to be_able_to(:delete, @album)
    end
  end
end
