require 'rails_helper'

describe MessageAuthorizer do
  before do
    @user = FactoryGirl.create(:person)
    @message = FactoryGirl.create(:message)
  end

  it 'should not update message' do
    expect(@user).to_not be_able_to(:update, @message)
  end

  it 'should not delete message' do
    expect(@user).to_not be_able_to(:delete, @message)
  end

  context 'owned by user' do
    before do
      @message.update_attributes!(person: @user)
    end

    it 'should update message' do
      expect(@user).to be_able_to(:update, @message)
    end

    it 'should delete message' do
      expect(@user).to be_able_to(:delete, @message)
    end
  end

  context 'message is not in a group' do
    context 'user is admin with manage_groups privilege' do
      before do
        @user.update_attributes!(admin: Admin.create!(manage_groups: true))
      end

      it 'should not update message' do
        expect(@user).to_not be_able_to(:update, @message)
      end

      it 'should not delete message' do
        expect(@user).to_not be_able_to(:delete, @message)
      end
    end
  end

  context 'message in a group' do
    before do
      @group = FactoryGirl.create(:group)
      @message.update_attributes!(group: @group)
    end

    it 'should not update message' do
      expect(@user).to_not be_able_to(:update, @message)
    end

    it 'should not delete message' do
      expect(@user).to_not be_able_to(:delete, @message)
    end

    context 'user is admin with manage_groups privilege' do
      before do
        @user.update_attributes!(admin: Admin.create!(manage_groups: true))
      end

      it 'should update message' do
        expect(@user).to be_able_to(:update, @message)
      end

      it 'should delete message' do
        expect(@user).to be_able_to(:delete, @message)
      end
    end

    context 'user is group admin' do
      before do
        @group.memberships.create(person: @user, admin: true)
      end

      it 'should update message' do
        expect(@user).to be_able_to(:update, @message)
      end

      it 'should delete message' do
        expect(@user).to be_able_to(:delete, @message)
      end
    end
  end
end
