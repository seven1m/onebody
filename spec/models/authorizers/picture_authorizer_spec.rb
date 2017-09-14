require 'rails_helper'

describe PictureAuthorizer do
  before do
    @user = FactoryGirl.create(:person)
    @picture = FactoryGirl.create(:picture)
  end

  it 'should not update picture' do
    expect(@user).to_not be_able_to(:update, @picture)
  end

  it 'should not delete picture' do
    expect(@user).to_not be_able_to(:delete, @picture)
  end

  context 'owned by user' do
    before do
      @picture.update_attributes!(person: @user)
    end

    it 'should update picture' do
      expect(@user).to be_able_to(:update, @picture)
    end

    it 'should delete picture' do
      expect(@user).to be_able_to(:delete, @picture)
    end
  end

  context 'picture in album in group' do
    before do
      @group = FactoryGirl.create(:group)
      @picture.album.update_attributes!(owner: @group)
    end

    context 'user is group member' do
      before do
        @group.memberships.create(person: @user)
      end

      it 'should create picture in album' do
        expect(@user).to be_able_to(:create, @picture.album.pictures.new)
      end

      it 'should not update picture' do
        expect(@user).to_not be_able_to(:update, @picture)
      end

      it 'should not delete picture' do
        expect(@user).to_not be_able_to(:delete, @picture)
      end

      context 'group does not allow pictures' do
        before do
          @group.update_attributes!(pictures: false)
        end

        it 'should create picture in album' do
          expect(@user).to_not be_able_to(:create, @picture.album.pictures.new)
        end
      end
    end

    context 'user is group admin' do
      before do
        @group.memberships.create(person: @user, admin: true)
      end

      it 'should update picture' do
        expect(@user).to be_able_to(:update, @picture)
      end

      it 'should delete picture' do
        expect(@user).to be_able_to(:delete, @picture)
      end
    end
  end

  context 'user is admin with manage_pictures privilege' do
    before do
      @user.update_attributes!(admin: Admin.create!(manage_pictures: true))
    end

    it 'should update picture' do
      expect(@user).to be_able_to(:update, @picture)
    end

    it 'should delete picture' do
      expect(@user).to be_able_to(:delete, @picture)
    end
  end
end
