require 'rails_helper'

describe MembershipAuthorizer do
  before do
    @user = FactoryGirl.create(:person)
    @group = FactoryGirl.create(:group)
    @membership = @group.memberships.create!(person: FactoryGirl.create(:person))
  end

  it 'should not update membership' do
    expect(@user).to_not be_able_to(:update, @membership)
  end

  it 'should not delete membership' do
    expect(@user).to_not be_able_to(:delete, @membership)
  end

  context 'owned by user' do
    before do
      @membership.update_attributes!(person: @user)
    end

    it 'should update membership' do
      expect(@user).to be_able_to(:update, @membership)
    end

    it 'should delete membership' do
      expect(@user).to be_able_to(:delete, @membership)
    end
  end

  context 'group does not require approval to join' do
    before do
      @group.update_attribute(:approval_required_to_join, false)
    end

    it 'should create membership' do
      expect(@user).to be_able_to(:create, @group.memberships.new)
    end
  end

  context 'user is admin with manage_groups privilege' do
    before do
      @user.update_attributes!(admin: Admin.create!(manage_groups: true))
    end

    it 'should create membership' do
      expect(@user).to be_able_to(:create, @group.memberships.new)
    end

    it 'should update membership' do
      expect(@user).to be_able_to(:update, @membership)
    end

    it 'should delete membership' do
      expect(@user).to be_able_to(:delete, @membership)
    end
  end

  context 'user is admin with edit_profiles privilege' do
    before do
      @user.update_attributes!(admin: Admin.create!(edit_profiles: true))
    end

    it 'should not create membership' do
      expect(@user).not_to be_able_to(:create, @group.memberships.new)
    end

    it 'should update membership' do
      expect(@user).to be_able_to(:update, @membership)
    end

    it 'should delete membership' do
      expect(@user).to be_able_to(:delete, @membership)
    end
  end

  context 'user is group admin' do
    before do
      @group.memberships.create(person: @user, admin: true)
    end

    it 'should create membership' do
      expect(@user).to be_able_to(:create, @group.memberships.new)
    end

    it 'should update membership' do
      expect(@user).to be_able_to(:update, @membership)
    end

    it 'should delete membership' do
      expect(@user).to be_able_to(:delete, @membership)
    end
  end

  context 'user is family member' do
    before do
      @spouse = FactoryGirl.create(:person, family: @user.family)
      @membership.update_attributes!(person: @spouse)
    end

    it 'should not create membership' do
      expect(@user).not_to be_able_to(:create, @group.memberships.new)
    end

    it 'should update membership' do
      expect(@user).to be_able_to(:update, @membership)
    end

    it 'should delete membership' do
      expect(@user).to be_able_to(:delete, @membership)
    end

    context 'user is child' do
      before do
        @user.update_attributes!(child: true)
      end

      it 'should not update membership' do
        expect(@user).to_not be_able_to(:update, @membership)
      end

      it 'should not delete membership' do
        expect(@user).to_not be_able_to(:delete, @membership)
      end
    end
  end
end
