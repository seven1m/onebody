require_relative '../rails_helper'

describe 'Privacy', type: :request do
  before do
    @user = FactoryGirl.create(:person)
    @head = FactoryGirl.create(:person)
    @spouse = FactoryGirl.create(:person, family: @head.family, first_name: 'Jane')
  end

  context 'given a child without parental consent' do
    before do
      @child = FactoryGirl.create(:person, family: @head.family, first_name: 'Megan', child: true)
    end

    context 'when viewed by a stranger' do
      before do
        sign_in_as @user
      end

      it 'should not show child on family page' do
        get "/families/#{@head.family_id}"
        expect(response).to be_success
        expect(response).to render_template('families/show')
        assert_select '.family td.avatar', 2 # not 3 (should not see child)
        expect(response.body).to_not match(/Megan/)
      end

      it 'should not show profile page of child' do
        get "/people/#{@child.id}"
        expect(response).to be_missing
      end

      it 'should not show child in search results' do
        get '/search', name: 'Megan'
        expect(response).to render_template('searches/create')
        assert_select 'body', /0 people found/
      end
    end

    context 'when viewed by adult in same family' do
      before do
        sign_in_as @head
      end

      it 'should show child on parent profile' do
        get "/families/#{@head.family_id}"
        expect(response).to be_success
        expect(response).to render_template('families/show')
        assert_select '.family td.avatar', 3
        expect(response.body).to match(/Megan/)
      end

      it 'should show profile page of child' do
        get "/people/#{@child.id}"
        expect(response).to be_success
      end

      it 'should not show child in search results' do
        get '/search', name: 'Megan'
        expect(response).to render_template('searches/create')
        assert_select 'body', /0 people found/
      end
    end

    it 'should not allow child to sign in' do
      post_sign_in_form @child.email
      expect(response).to redirect_to('/pages/system/unauthorized')
    end

    it 'should give child parental consent from parent' do
      sign_in_as @head
      get "/people/#{@child.id}/privacy/edit"
      expect(response).to be_success
      expect(response).to render_template('privacies/edit')
      assert_select 'body', minimum: 1, text: /you have not given consent/
      assert_select 'li', minimum: 1, text: /Privacy Policy/
      assert_select 'button[name="agree_commit"]', 1
      put "/people/#{@child.id}/privacy", agree: 'I Agree.'
      expect(response).to be_redirect
      follow_redirect!
      expect(response).to render_template('privacies/edit')
      assert_select 'div.callout', /Agreement saved\./
      @child.reload
      expect(@child.parental_consent).to_not be_nil
      expect(@child.parental_consent).to include("#{@head.name} \(#{@head.id}\)")
      assert_select 'body', minimum: 1, text: /profile has parental consent/
    end
  end

  context 'given child with parental consent' do
    before do
      @child = FactoryGirl.create(:person, family: @head.family, first_name: 'Megan', child: true, parental_consent: 'consent')
    end

    it 'should allow child to sign in' do
      sign_in_as @child
    end
  end
end
