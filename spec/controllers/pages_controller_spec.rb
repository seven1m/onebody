require_relative '../rails_helper'

describe PagesController, type: :controller do
  before do
    @admin = FactoryGirl.create(:person, admin: Admin.create(edit_pages: true))
    @person = FactoryGirl.create(:person)
    @parent_page = FactoryGirl.create(:page, slug: 'foo')
    @child_page = FactoryGirl.create(:page, slug: 'baz', parent: @parent_page)
  end

  it 'should show a top level page based on path' do
    get :show_for_public, path: 'foo'
    expect(response).to be_success
    expect(assigns(:page)).to eq(@parent_page)
  end

  it 'should show a child level page based on path' do
    get :show_for_public, path: 'foo/baz'
    expect(response).to be_success
    expect(assigns(:page)).to eq(@child_page)
  end

  it 'should not show a page if it does not exist' do
    get :show_for_public, path: 'foo/bar'
    expect(response).to be_redirect
  end

  it 'should not show a page if it is not published' do
    @parent_page.update_attribute(:published, false)
    get :show_for_public, path: 'foo'
    expect(response).to be_missing
  end

  # admin actions...

  it 'should show edit page form' do
    get :edit, { id: @child_page.id }, logged_in_id: @admin.id
    expect(response).to be_success
    expect(assigns(:page)).to eq(@child_page)
  end

  it 'should update a page' do
    post :update, { id: @child_page.id, page: { title: 'Test', slug: 'test', body: 'the body' } }, logged_in_id: @admin.id
    expect(response).to redirect_to(pages_path)
    expect(flash[:notice]).to match(/saved/)
    expect(@child_page.reload.title).to eq('Test')
    expect(@child_page.slug).to eq('test')
    expect(@child_page.body).to eq('the body')
  end

  it 'should not edit a page unless user is admin' do
    get :edit, { id: @child_page.id }, logged_in_id: @person.id
    expect(response).to be_unauthorized
    post :update, { id: @child_page.id, page: { title: 'Test', slug: 'test', body: 'the body' } }, logged_in_id: @person.id
    expect(response).to be_unauthorized
  end
end
