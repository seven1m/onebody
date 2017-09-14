require_relative '../rails_helper'

describe NewsItem, type: :model do
  describe 'published' do
    it 'should not overwrite published date if it has been specified' do
      @news_item = FactoryGirl.create(:news_item, published: Date.current - 30)
      expect(@news_item.published).to be < Date.current
    end

    it 'should update published date if it is unspecified' do
      @news_item = FactoryGirl.create(:news_item)
      expect(@news_item.published).to_not be_nil
    end
  end
end
