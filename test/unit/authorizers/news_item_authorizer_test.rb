require_relative '../../test_helper'

class NewsItemAuthorizerTest < ActiveSupport::TestCase

  setup do
    @user = FactoryGirl.create(:person)
    @news_item = FactoryGirl.create(:news_item)
  end

  should 'not update news item' do
    assert_cannot @user, :update, @news_item
  end

  should 'not delete news item' do
    assert_cannot @user, :delete, @news_item
  end

  context 'user is owner of news item' do
    setup do
      @news_item.update_attributes!(person: @user)
    end

    should 'update news item' do
      assert_can @user, :update, @news_item
    end

    should 'delete news item' do
      assert_can @user, :delete, @news_item
    end
  end

  context 'user is admin with manage_news privilege' do
    setup do
      @user.update_attributes!(admin: Admin.create!(manage_news: true))
    end

    should 'update news item' do
      assert_can @user, :update, @news_item
    end

    should 'delete news item' do
      assert_can @user, :delete, @news_item
    end
  end

end
