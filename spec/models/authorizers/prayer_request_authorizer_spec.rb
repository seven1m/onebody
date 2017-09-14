require 'rails_helper'

describe PrayerRequestAuthorizer do
  before do
    @user = FactoryGirl.create(:person)
    @prayer_request = FactoryGirl.create(:prayer_request)
    @group = @prayer_request.group
  end

  it 'should not update prayer request' do
    expect(@user).to_not be_able_to(:update, @prayer_request)
  end

  it 'should not delete prayer request' do
    expect(@user).to_not be_able_to(:delete, @prayer_request)
  end

  context 'owned by user' do
    before do
      @prayer_request.update_attributes!(person: @user)
    end

    it 'should update prayer request' do
      expect(@user).to be_able_to(:update, @prayer_request)
    end

    it 'should delete prayer request' do
      expect(@user).to be_able_to(:delete, @prayer_request)
    end
  end

  context 'user is admin with manage_groups privilege' do
    before do
      @user.update_attributes!(admin: Admin.create!(manage_groups: true))
    end

    it 'should update prayer request' do
      expect(@user).to be_able_to(:update, @prayer_request)
    end

    it 'should delete prayer request' do
      expect(@user).to be_able_to(:delete, @prayer_request)
    end
  end

  context 'user is group member' do
    before do
      @group.memberships.create(person: @user)
    end

    it 'should not update prayer request' do
      expect(@user).to_not be_able_to(:update, @prayer_request)
    end

    it 'should not delete prayer request' do
      expect(@user).to_not be_able_to(:delete, @prayer_request)
    end
  end

  context 'user is group admin' do
    before do
      @group.memberships.create(person: @user, admin: true)
    end

    it 'should update prayer request' do
      expect(@user).to be_able_to(:update, @prayer_request)
    end

    it 'should delete prayer request' do
      expect(@user).to be_able_to(:delete, @prayer_request)
    end
  end
end
