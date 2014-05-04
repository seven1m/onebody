require_relative '../test_helper'

class NewsItemTest < ActiveSupport::TestCase

  context 'Published Date' do

    should 'not overwrite published date if it has been specified' do
      last_month = Date.today - 30
      @news_item = FactoryGirl.create(:news_item, published: last_month)
      assert_equal last_month.strftime('%m/%d/%Y'), @news_item.published.strftime('%m/%d/%Y')
      assert @news_item.created_at > last_month
    end

    should 'update published date if it is unspecified' do
      @news_item = FactoryGirl.create(:news_item)
      assert_not_nil @news_item.published
    end

  end

end
