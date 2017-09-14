require 'rails_helper'

describe NewsItemAuthorizer do
  before do
    @user = FactoryGirl.create(:person)
    @news_item = FactoryGirl.create(:news_item)
  end

  it 'should not update news item' do
    expect(@user).to_not be_able_to(:update, @news_item)
  end

  it 'should not delete news item' do
    expect(@user).to_not be_able_to(:delete, @news_item)
  end

  context 'user is owner of news item' do
    before do
      @news_item.update_attributes!(person: @user)
    end

    it 'should update news item' do
      expect(@user).to be_able_to(:update, @news_item)
    end

    it 'should delete news item' do
      expect(@user).to be_able_to(:delete, @news_item)
    end
  end

  context 'user is admin with manage_news privilege' do
    before do
      @user.update_attributes!(admin: Admin.create!(manage_news: true))
    end

    it 'should update news item' do
      expect(@user).to be_able_to(:update, @news_item)
    end

    it 'should delete news item' do
      expect(@user).to be_able_to(:delete, @news_item)
    end
  end
end
