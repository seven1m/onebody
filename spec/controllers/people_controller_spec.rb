require_relative '../spec_helper'

GLOBAL_SUPER_ADMIN_EMAIL = 'support@example.com' unless defined?(GLOBAL_SUPER_ADMIN_EMAIL) and GLOBAL_SUPER_ADMIN_EMAIL == 'support@example.com'

describe PeopleController do
  render_views

  before do
    @person, @other_person = FactoryGirl.create_list(:person, 2)
    @limited_person = FactoryGirl.create(:person, full_access: false)
  end

  it "should redirect the index action to the currently logged in person" do
    get :index, nil, {logged_in_id: @person.id}
    expect(response).to redirect_to(action: 'show', id: @person.id)
  end

  it "should show a person" do
    get :show, {id: @person.id}, {logged_in_id: @person.id} # myself
    expect(response).to be_success
    expect(response).to render_template('show')
    get :show, {id: @person.id}, {logged_in_id: @other_person.id} # someone else
    expect(response).to be_success
    expect(response).to render_template('show')
  end

  it "should show a limited view of a person" do
    get :show, {id: @person.id}, {logged_in_id: @limited_person.id}
    expect(response).to be_success
    expect(response).to render_template('show_limited')
  end

  it "should not show a person if they are invisible to the logged in user" do
    @person.update_attribute :visible, false
    get :show, {id: @person.id}, {logged_in_id: @other_person.id}
    expect(response).to be_missing
  end

  it "should create a person update" do
    Setting.set(Site.current.id, 'Features', 'Updates Must Be Approved', true)
    get :edit, {id: @person.id}, {logged_in_id: @person.id}
    expect(response).to be_success
    post :update,
      {
        id: @person.id,
        person: {
          first_name: 'Bob',
          last_name: 'Smith'
        },
        family: {
          name: 'Bob Smith',
          last_name: 'Smith'
        }
      },
      {logged_in_id: @person.id}
    expect(response).to redirect_to(person_path(@person))
    expect(@person.reload.first_name).to eq("John") # should not change person
    expect(@person.updates.count).to eq(1)
  end

  it "should edit favorites and other non-basic person information" do
    post :update,
      {
        id: @person.id,
        person: {
          testimony: 'testimony',
          interests: 'interests'
        }
      },
      {logged_in_id: @person.id}
    expect(response).to redirect_to(person_path(@person))
    expect(@person.reload.testimony).to eq("testimony")
    expect(@person.interests).to eq("interests")
    expect(@person.updates.count).to eq(0)
  end

  it "should edit a person basics when user is admin" do
    @other_person.admin = Admin.create!(edit_profiles: true)
    @other_person.save!
    post :update,
      {
        id: @person.id,
        person: {
          first_name: 'Bob',
          last_name: 'Smith'
        },
        family: {
          name: 'Bob Smith',
          last_name: 'Smith'
        }
      },
      {logged_in_id: @other_person.id}
    expect(response).to redirect_to(person_path(@person))
    expect(@person.reload.first_name).to eq("Bob")
    expect(@person.updates.count).to eq(0)
  end

  it "should create a person" do
    @other_person.admin = Admin.create!(edit_profiles: true)
    @other_person.save!
    @family = @person.family
    post :create,
      {
        person: {
          first_name: 'Todd',
          last_name: 'Jones',
          family_id: @family.id,
          child: '0'
        }
      },
      {logged_in_id: @other_person.id}
    expect(response).to redirect_to(family_path(@family))
    expect(@family.people.where(first_name: "Todd").first).to be
  end

  it "should delete a person" do
    @other_person.admin = Admin.create!(edit_profiles: true)
    @other_person.save!
    post :destroy, {id: @person.id}, {logged_in_id: @other_person.id}
    expect(@person.reload).to be_deleted
  end

  it "should not delete self" do
    @person.admin = Admin.create!(edit_profiles: true)
    @person.save!
    post :destroy, {id: @person.id}, {logged_in_id: @person.id}
    expect(response).to be_unauthorized
    expect(@person.reload).to_not be_deleted
  end

  it "should not delete a person unless admin" do
    post :destroy, {id: @person.id}, {logged_in_id: @other_person.id}
    expect(response).to be_unauthorized
    post :destroy, {id: @person.id}, {logged_in_id: @other_person.id}
    expect(response).to be_unauthorized
  end

  it "should not show xml unless user can export data" do
    expect {
      get :show, {id: @person.id, format: 'xml'}, {logged_in_id: @person.id}
    }.to raise_error(ActionController::UnknownFormat)
  end

  it "should show xml for admin who can export data" do
    @other_person.admin = Admin.create!(export_data: true)
    @other_person.save!
    get :show, {id: @person.id, format: 'xml'}, {logged_in_id: @other_person.id}
    expect(response).to be_success
  end

  it "should show business listing" do
    @person.update_attributes!(business_name: 'Tim Morgan Enterprises')
    get :show, {id: @person.id, business: true}, {logged_in_id: @person.id}
    expect(response).to be_success
    assert_select 'body', /Tim Morgan Enterprises/
  end

  it "should not allow deletion of a global super admin" do
     @super_admin = FactoryGirl.create(:person, admin: Admin.create(super_admin: true))
     @global_super_admin = FactoryGirl.create(:person, email: 'support@example.com')
     post :destroy, {id: @global_super_admin.id}, {logged_in_id: @super_admin.id}
     expect(response).to be_unauthorized
  end

  it "should not error when viewing a person not in a family" do
    @admin = FactoryGirl.create(:person, admin: Admin.create(view_hidden_profiles: true))
    @person = Person.create!(first_name: 'Deanna', last_name: 'Troi', child: false, visible_to_everyone: true)
    # normal person should not see
    assert_nothing_raised do
      get :show, {id: @person.id}, {logged_in_id: @other_person.id}
    end
    expect(response).to be_missing
    # admin should see a message
    assert_nothing_raised do
      get :show, {id: @person.id}, {logged_in_id: @admin.id}
    end
    expect(response).to be_success
    assert_select 'div.alert', I18n.t('people.no_family_for_this_person')
  end
end
