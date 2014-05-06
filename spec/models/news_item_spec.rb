require_relative '../spec_helper'

describe NewsItem do

  context 'Published Date' do

    it 'should not overwrite published date if it has been specified' do
      last_month = Date.today - 30
      @news_item = FactoryGirl.create(:news_item, published: last_month)
      expect(@news_item.published.strftime("%m/%d/%Y")).to eq(last_month.strftime("%m/%d/%Y"))
      expect(@news_item.created_at > last_month).to be
    end

    it 'should update published date if it is unspecified' do
      @news_item = FactoryGirl.create(:news_item)
      expect(@news_item.published).to_not be_nil
    end

  end

end
