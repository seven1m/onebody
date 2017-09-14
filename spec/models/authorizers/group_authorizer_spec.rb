require 'rails_helper'

describe GroupAuthorizer do
  before do
    @user = FactoryGirl.create(:person)
    @group = FactoryGirl.create(:group)
  end

  it 'should read group' do
    expect(@user).to be_able_to(:read, @group)
  end

  it 'should not update group' do
    expect(@user).to_not be_able_to(:update, @group)
  end

  it 'should not delete group' do
    expect(@user).to_not be_able_to(:delete, @group)
  end

  context 'group is hidden' do
    before do
      @group.update_attributes!(hidden: true)
    end

    it 'should not read group' do
      expect(@user).to_not be_able_to(:read, @group)
    end

    context 'user is a group member' do
      before do
        @group.memberships.create!(person: @user)
      end

      it 'should read group' do
        expect(@user).to be_able_to(:read, @group)
      end
    end
  end

  context 'group is private' do
    before do
      @group.update_attributes!(private: true)
    end

    it 'should not read group' do
      expect(@user).to_not be_able_to(:read, @group)
    end

    context 'user is a group member' do
      before do
        @group.memberships.create!(person: @user)
      end

      it 'should read group' do
        expect(@user).to be_able_to(:read, @group)
      end
    end
  end

  context 'user is a group member' do
    before do
      @group.memberships.create(person: @user)
    end

    it 'should read group' do
      expect(@user).to be_able_to(:read, @group)
    end

    it 'should not update group' do
      expect(@user).to_not be_able_to(:update, @group)
    end

    it 'should not delete group' do
      expect(@user).to_not be_able_to(:delete, @group)
    end
  end

  context 'user is a group admin' do
    before do
      @group.memberships.create(person: @user, admin: true)
    end

    it 'should update group' do
      expect(@user).to be_able_to(:update, @group)
    end

    it 'should delete group' do
      expect(@user).to be_able_to(:delete, @group)
    end
  end

  context 'user is an admin with manage_groups privilege' do
    before do
      @user.update_attributes!(admin: Admin.create!(manage_groups: true))
    end

    it 'should read group' do
      expect(@user).to be_able_to(:read, @group)
    end

    it 'should update group' do
      expect(@user).to be_able_to(:update, @group)
    end

    it 'should delete group' do
      expect(@user).to be_able_to(:delete, @group)
    end
  end
end
