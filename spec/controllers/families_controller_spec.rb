require_relative '../rails_helper'

describe FamiliesController, type: :controller do
  before do
    @person, @other_person = FactoryGirl.create_list(:person, 2)
    @family = @person.family
    @child = FactoryGirl.create(:person, family: @family, birthday: 1.year.ago, gender: 'Female', child: nil)
    @admin = FactoryGirl.create(:person, admin: Admin.create(edit_profiles: true))
  end

  it 'should show a family' do
    get :show, { id: @family.id }, logged_in_id: @person.id
    expect(response).to be_success
    expect(response).to render_template('show')
    expect(assigns(:family)).to eq(@family)
    expect(assigns(:people)).to eq([@person, @child])
  end

  it 'should not show hidden people in the family' do
    get :show, { id: @family.id }, logged_in_id: @other_person.id
    expect(response).to be_success
    expect(response).to render_template('show')
    expect(assigns(:family)).to eq(@family)
    expect(assigns(:people)).to eq([@person])
  end

  it 'should not show the family unless it is visible' do
    @family.update_attributes! visible: false
    get :show, { id: @family.id }, logged_in_id: @other_person.id
    expect(response).to be_missing
  end

  it 'should create a new family' do
    get :new, nil, logged_in_id: @admin.id
    expect(response).to be_success
    first_name = 'Mary'
    last_name = 'Jones'
    name = "#{first_name} #{last_name}"
    post :create,
         { family: { name: name, last_name: last_name, address1: '123 S Morgan st.', address2: '', city: 'Tulsa', state: 'OK', zip: '74120', home_phone: '123-456-7890' } },
         logged_in_id: @admin.id
    expect(response).to be_redirect
  end

  it 'should not create a new family unless user is admin' do
    get :new, nil, logged_in_id: @person.id
    expect(response).to be_forbidden
    first_name = 'Mary'
    last_name = 'Jones'
    name = "#{first_name} #{last_name}"
    post :create,
         { family: { name: name, last_name: last_name, address1: '123 S Morgan st.', address2: '', city: 'Tulsa', state: 'OK', zip: '74120', home_phone: '123-456-7890' } },
         logged_in_id: @person.id
    expect(response).to be_forbidden
  end

  it 'should edit a family' do
    get :edit, { id: @family.id }, logged_in_id: @admin.id
    expect(response).to be_success
    post :update,
         { id: @family.id, family: { name: @family.name, last_name: @family.last_name, address1: @family.address1, address2: @family.address2, city: @family.city, state: @family.state, zip: @family.zip, home_phone: @family.home_phone } },
         logged_in_id: @admin.id
    expect(response).to be_redirect
  end

  it 'should not show xml unless user can export data' do
    expect do
      get :show, { id: @family.id, format: 'xml' }, logged_in_id: @person.id
    end.to raise_error(ActionController::UnknownFormat)
  end

  it 'should show xml for admin who can export data' do
    @other_person.admin = Admin.create!(export_data: true)
    @other_person.save!
    get :show, { id: @family.id, format: 'xml' }, logged_in_id: @other_person.id
    expect(response).to be_success
  end
end
