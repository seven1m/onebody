require_relative '../rails_helper'

describe SessionsController, type: :controller do

  before do
    Setting.set_global('Features', 'SSL', true)
    @person = FactoryGirl.create(:person, password: 'secret')
  end

  it "should redirect show action to new action" do
    get :show
    expect(response).to redirect_to(new_session_path)
  end

  it "should present a login form" do
    get :new
    expect(response).to be_success
    expect(response).to render_template('new')
  end

  it "should sign in a user" do
    post :create, {email: @person.email, password: 'secret'}
    expect(flash[:warning]).to be_nil
    expect(response).to redirect_to(stream_path)
    expect(session[:logged_in_id]).to eq(@person.id)
  end

  it "should sign out a user" do
    post :destroy
    expect(response).to redirect_to(root_path)
    expect(session[:logged_in_id]).to be_nil
  end

  it "should redirect to original location after sign in" do
    post :create, {email: @person.email, password: 'secret', from: "/groups"}
    expect(flash[:warning]).to be_nil
    expect(response).to redirect_to(groups_path)
  end

  it 'should not redirect off-site' do
    post :create, {email: @person.email, password: 'secret', from: "http://google.com/groups"}
    expect(response).to redirect_to(groups_path)
  end

end
