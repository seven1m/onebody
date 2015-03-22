require_relative '../../rails_helper'

describe CustomReportAuthorizer do
  before do
    @user = FactoryGirl.create(:person)
    @custom_report = FactoryGirl.create(:custom_report)
  end

  context 'A user with no authorizations ' do
    it 'should not be able to read reports' do
      expect(@user).to_not be_able_to(:read, @custom_report)
    end

    it 'should not be able to create reports' do
      expect(@user).to_not be_able_to(:create, @custom_report)
    end

    it 'should not be able to update reports' do
      expect(@user).to_not be_able_to(:update, @custom_report)
    end

    it 'should not be able to delete reports' do
      expect(@user).to_not be_able_to(:delete, @custom_report)
    end
  end

  context 'A user with Run Reports privileges' do
    before do
      @user.update_attributes!(admin: Admin.create!(run_reports: true))
    end

    it 'should be able to read reports' do
      expect(@user).to be_able_to(:read, @custom_report)
    end

    it 'should not be able to create reports' do
      expect(@user).to_not be_able_to(:create, @custom_report)
    end

    it 'should not be able to update reports' do
      expect(@user).to_not be_able_to(:update, @custom_report)
    end

    it 'should not be able to delete reports' do
      expect(@user).to_not be_able_to(:delete, @custom_report)
    end
  end

  context 'A user with Manage Reports privileges' do
    before do
      @user.update_attributes!(admin: Admin.create!(manage_reports: true))
    end

    it 'should not be able to read reports' do
      expect(@user).to_not be_able_to(:read, @custom_report)
    end

    it 'should not be able to create reports' do
      expect(@user).to be_able_to(:create, @custom_report)
    end

    it 'should not be able to update reports' do
      expect(@user).to be_able_to(:update, @custom_report)
    end

    it 'should not be able to delete reports' do
      expect(@user).to be_able_to(:delete, @custom_report)
    end
  end

end
