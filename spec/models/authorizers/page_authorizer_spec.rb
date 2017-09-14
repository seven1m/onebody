require 'rails_helper'

describe PageAuthorizer do
  before do
    @user = FactoryGirl.create(:person)
    @page = FactoryGirl.create(:page)
  end

  it 'should not update page' do
    expect(@user).to_not be_able_to(:update, @page)
  end

  it 'should not delete page' do
    expect(@user).to_not be_able_to(:delete, @page)
  end

  context 'user is admin with edit_pages privilege' do
    before do
      @user.update_attributes!(admin: Admin.create!(edit_pages: true))
    end

    it 'should update page' do
      expect(@user).to be_able_to(:update, @page)
    end

    it 'should delete page' do
      expect(@user).to be_able_to(:delete, @page)
    end
  end
end
