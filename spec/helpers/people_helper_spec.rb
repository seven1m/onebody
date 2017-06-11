require_relative '../rails_helper'

describe PeopleHelper, type: :helper do
  describe 'render_message_html_body' do
    it 'should have social networks' do
      @person = FactoryGirl.build(:person)
      @person.twitter = '@username'
      expect(has_social_networks?(@person)).to eq(true)
      @person.facebook_url = 'https://www.facebook.com/tester'
      expect(has_social_networks?(@person)).to eq(true)
      @person.twitter = nil
      expect(has_social_networks?(@person)).to eq(true)
    end

    it 'should not have social networks' do
      @person = FactoryGirl.build(:person)
      expect(has_social_networks?(@person)).to eq(false)
    end

    it 'should have a twitter user url' do
      @person = FactoryGirl.create(:person, twitter: '@username')
      expect(twitter_url(@person)).to eq('https://twitter.com/username')
    end
  end
end
