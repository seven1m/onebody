require 'rails_helper'

describe SessionsController, type: :controller do
  before do
    Setting.set_global('Features', 'SSL', true)
    @person = FactoryGirl.create(:person, password: 'secret')
  end

  describe '#show' do
    it 'redirects to new action' do
      get :show
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe '#new' do
    context do
      it 'renders the new template' do
        get :new
        expect(response).to be_success
        expect(response).to render_template('new')
      end
    end

    context 'there are no users' do
      before do
        Person.delete_all
      end

      it 'redirects to the setup path' do
        get :new
        expect(response).to redirect_to(new_setup_path)
      end
    end
  end

  describe '#create' do
    context 'correct password' do
      it 'sets logged_in_id and redirects' do
        post :create,
             params: { email: @person.email.upcase, password: 'secret' }
        expect(flash[:warning]).to be_nil
        expect(session[:logged_in_id]).to eq(@person.id)
        expect(session[:logged_in_name]).to eq(@person.name)
        expect(session[:ip_address]).to eq('0.0.0.0')
        expect(response).to redirect_to(stream_path)
      end
    end

    context 'given incorrect password' do
      before do
        post :create,
             params: { email: @person.email.upcase, password: 'wrong' }
      end

      render_views

      it 'renders the new template with an error' do
        expect(assigns[:focus_password]).to eq(true)
        expect(response).to render_template(:new)
        expect(response.body).to match(/password you entered does not match/)
      end

      it 'creates a signing failure record' do
        expect(SigninFailure.count).to eq(1)
        expect(SigninFailure.last.attributes).to include(
          'email' => @person.email.upcase,
          'ip'    => '0.0.0.0'
        )
      end
    end

    context 'given email not found' do
      before do
        post :create,
             params: { email: 'bad@example.com', password: 'secret' }
      end

      render_views

      it 'renders the new template with an error' do
        expect(assigns[:focus_password]).to be_nil
        expect(response).to render_template(:new)
        expect(response.body).to match(/email address cannot be found/)
      end

      it 'creates a signing failure record' do
        expect(SigninFailure.count).to eq(1)
        expect(SigninFailure.last.attributes).to include(
          'email' => 'bad@example.com',
          'ip'    => '0.0.0.0'
        )
      end
    end

    context 'given from param' do
      it 'redirects to from param after sign in' do
        post :create,
             params: { email: @person.email, password: 'secret', from: '/groups' }
        expect(response).to redirect_to(groups_path)
      end
    end

    context 'given from param with a domain name' do
      it 'does not redirect off-site' do
        post :create,
             params: { email: @person.email, password: 'secret', from: 'http://google.com/foo' }
        expect(response).to redirect_to('/foo')
      end
    end

    context 'given from param without a leading slash' do
      it 'does not redirect off-site' do
        post :create,
             params: { email: @person.email, password: 'secret', from: 'badguy.com' }
        expect(response).to redirect_to('/badguy.com')
      end
    end
  end

  describe '#create_from_external_provider' do
    context 'no existing user given the provider' do
      before do
        omni_auth = {
          'provider' => 'facebook',
          'uid' => 10_001,
          'info' => {
            'email' => 'ME_FACEBOOK@EXAMPLE.COM',
            'first_name' => 'Martin',
            'last_name' => 'Luther',
            'urls' => {
              'Facebook' => 'facebook_profile_url'
            }
          }
        }
        request.env['omniauth.auth'] = omni_auth
      end

      it 'sets logged_in_id and redirects (new user)' do
        post :create_from_external_provider
        @person = Person.where(
          provider: 'facebook',
          uid: 10_001
        ).first
        expect(flash[:warning]).to be_nil
        expect(session[:logged_in_id]).to eq(@person.id)
        expect(session[:logged_in_name]).to eq(@person.name)
        expect(session[:ip_address]).to eq('0.0.0.0')
        expect(response).to redirect_to("http://test.host/people/#{@person.id}")
      end

      it 'sets logged_in_id and redirects (existing user)' do
        @person = FactoryGirl.create(:person, uid: 10_001, provider: 'facebook', status: :pending)
        post :create_from_external_provider
        expect(flash[:warning]).to be_nil
        expect(session[:logged_in_id]).to eq(@person.id)
        expect(session[:logged_in_name]).to eq(@person.name)
        expect(session[:ip_address]).to eq('0.0.0.0')
        expect(response).to redirect_to("http://test.host/people/#{@person.id}")
      end
    end
  end

  describe '#destroy' do
    it 'unsets logged_in_id and redirects to the root path' do
      post :destroy
      expect(session[:logged_in_id]).to be_nil
      expect(response).to redirect_to(root_path)
    end
  end
end
