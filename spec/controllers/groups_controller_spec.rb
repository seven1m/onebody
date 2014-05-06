require_relative '../spec_helper'

describe GroupsController do
  render_views

  before do
    @person, @other_person = FactoryGirl.create_list(:person, 2)
    @group = FactoryGirl.create(:group, creator: @person, category: 'Small Groups')
    @group.memberships.create(person: @person, admin: true)
  end

  it "should show a group" do
    get :show, {id: @group.id}, {logged_in_id: @person.id}
    expect(response).to be_success
    assert_tag tag: 'h2', content: Regexp.new(@group.name)
  end

  it "should not show a group if group is private and user is not a member of the group" do
    @private_group = FactoryGirl.create(:group, private: true)
    get :show, {id: @private_group.id}, {logged_in_id: @person.id}
    expect(response).to be_missing
  end

  it "should not show a group if it is hidden" do
    @hidden_group = FactoryGirl.create(:group, hidden: true)
    get :show, {id: @hidden_group.id}, {logged_in_id: @person.id}
    expect(response).to be_missing
  end

  it "should show a hidden group if the user can manage groups" do
    @hidden_group = FactoryGirl.create(:group, hidden: true)
    @admin = FactoryGirl.create(:person, :admin_manage_groups)
    get :show, {id: @hidden_group.id}, {logged_in_id: @admin.id}
    expect(response).to be_success
    assert_tag tag: 'h2', content: Regexp.new(@hidden_group.name)
  end

  it "should list a person's groups" do
    get :index, {person_id: @person.id}, {logged_in_id: @person.id}
    expect(response).to be_success
    expect(assigns(:person).groups.length).to eq(1)
  end

  it "should not list a person's hidden groups" do
    @group.update_attribute :hidden, true
    get :index, {person_id: @person.id}, {logged_in_id: @person.id}
    assert_no_tag tag: 'tr', attributes: {class: 'grayed hidden-group'}
  end

  it "should list a person's hidden groups if the user can manage groups" do
    @admin = FactoryGirl.create(:person, :admin_manage_groups)
    @group.update_attribute :hidden, true
    get :index, {person_id: @person.id}, {logged_in_id: @admin.id}
    assert_tag tag: 'tr', attributes: {class: 'grayed hidden-group'}
  end

  it "should search for groups by name" do
    FactoryGirl.create(:group, name: 'foo')
    get :index, {name: 'foo'}, {logged_in_id: @person.id}
    expect(assigns(:groups).length).to eq(1)
  end

  it "should search for groups by category" do
    get :index, {category: 'Small Groups'}, {logged_in_id: @person.id}
    expect(assigns(:groups).length).to eq(1)
  end

  it "should list a person's unapproved groups" do
    Group.delete_all
    @group = FactoryGirl.create(:group, creator_id: @person.id, approved: false)
    @group.memberships.create(person: @person, admin: true)
    2.times { FactoryGirl.create(:group, approved: false) }
    get :index, nil, {logged_in_id: @person.id}
    expect(assigns(:unapproved_groups).length).to eq(1)
  end

  it "should list all unapproved groups if the user can manage groups" do
    @admin = FactoryGirl.create(:person, :admin_manage_groups)
    Group.delete_all
    2.times { FactoryGirl.create(:group, approved: false) }
    get :index, nil, {logged_in_id: @admin.id}
    expect(assigns(:unapproved_groups).length).to eq(2)
  end

  it "should add a group photo" do
    @group.photo = nil
    expect(@group.photo).to_not be_exists
    post :update, {id: @group.id, group: {photo: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/image.jpg'), 'image/jpeg', true)}}, {logged_in_id: @person.id}
    expect(response).to redirect_to(group_path(@group))
    expect(Group.find(@group.id).photo).to be_exists
  end

  it "should remove a group photo" do
    @group.photo = File.open(Rails.root.join('spec/fixtures/files/image.jpg'))
    @group.save!
    expect(@group.photo).to be_exists
    post :update, {id: @group.id, group: {photo: 'remove'}}, {logged_in_id: @person.id}
    expect(response).to redirect_to(group_path(@group))
    expect(Group.find(@group.id).photo).to_not be_exists
  end

  it "should edit a group" do
    get :edit, {id: @group.id}, {logged_in_id: @person.id}
    expect(response).to be_success
    post :update, {id: @group.id, group: {name: 'test name', category: 'test cat'}}, {logged_in_id: @person.id}
    expect(response).to redirect_to(group_path(@group))
    expect(@group.reload.name).to eq("test name")
    expect(@group.category).to eq("test cat")
  end

  it "should not edit a group unless user is group admin or can manage groups" do
    get :edit, {id: @group.id}, {logged_in_id: @other_person.id}
    expect(response).to be_unauthorized
    post :update, {id: @group.id, group: {name: 'test name', category: 'test cat'}}, {logged_in_id: @other_person.id}
    expect(response).to be_unauthorized
  end

  it "should create a group pending approval" do
    get :new, nil, {logged_in_id: @person.id}
    expect(response).to be_success
    group_count = Group.count
    post :create, {group: {name: 'test name', category: 'test cat'}}, {logged_in_id: @person.id}
    expect(response).to be_redirect
    expect(Group.count).to eq(group_count + 1)
    new_group = Group.last
    expect(new_group.name).to eq("test name")
    expect(new_group.category).to eq("test cat")
    expect(new_group).to_not be_approved
  end

  it "should create an approved group if user can manage groups" do
    @admin = FactoryGirl.create(:person, :admin_manage_groups)
    get :new, nil, {logged_in_id: @admin.id}
    expect(response).to be_success
    group_count = Group.count
    post :create, {group: {name: 'test name', category: 'test cat'}}, {logged_in_id: @admin.id}
    expect(response).to be_redirect
    expect(Group.count).to eq(group_count + 1)
    new_group = Group.last
    expect(new_group.name).to eq("test name")
    expect(new_group.category).to eq("test cat")
    expect(new_group).to be_approved
  end

  it "should not allow creation of groups if the site has reached limit" do
    Site.current.update_attribute(:max_groups, 1000)
    post :create, {group: {name: 'test name 1', category: 'test cat 1'}}, {logged_in_id: @person.id}
    expect(response).to be_redirect
    Site.current.update_attribute(:max_groups, 1)
    post :create, {group: {name: 'test name 2', category: 'test cat 2'}}, {logged_in_id: @person.id}
    expect(response).to be_unauthorized
    Site.current.update_attribute(:max_groups, nil)
    post :create, {group: {name: 'test name 3', category: 'test cat 3'}}, {logged_in_id: @person.id}
    expect(response).to be_redirect
  end

  it "should batch edit groups" do
    @admin = FactoryGirl.create(:person, :admin_manage_groups)
    @group2 = FactoryGirl.create(:group)
    get :batch, nil, {logged_in_id: @admin.id}
    expect(response).to be_success
    expect(response).to render_template(:batch)
    # regular post
    post :batch, {groups: {@group.id.to_s => {name: "foobar", members_send: "0"}, @group2.id.to_s => {address: 'baz'}}}, {logged_in_id: @admin.id}
    expect(response).to be_success
    expect(response).to render_template(:batch)
    expect(@group.reload.name).to eq("foobar")
    expect(@group).to_not be_members_send
    expect(@group2.reload.address).to eq("baz")
    # ajax post
    post :batch, {format: 'js', groups: {@group.id.to_s => {name: "lorem", members_send: "true"}, @group2.id.to_s => {address: 'ipsum'}}}, {logged_in_id: @admin.id}
    expect(response).to be_success
    expect(response).to render_template(:batch)
    expect(@group.reload.name).to eq("lorem")
    expect(@group).to be_members_send
    expect(@group2.reload.address).to eq("ipsum")
  end

  it 'should report errors when batch editing groups' do
    @admin = FactoryGirl.create(:person, :admin_manage_groups)
    # regular post
    post :batch, {groups: {@group.id.to_s => {address: "bad*address"}}}, {logged_in_id: @admin.id}
    expect(response).to be_success
    expect(response).to render_template(:batch)
    assert_select "#group#{@group.id} .errors", I18n.t('activerecord.errors.models.group.attributes.address.invalid')
    # ajax post
    post :batch, {format: 'js', groups: {@group.id.to_s => {address: "bad*address"}}}, {logged_in_id: @admin.id}
    expect(response).to be_success
    expect(response).to render_template(:batch)
    expect(@response.body).to match(/\$\("#group#{@group.id}"\)\.addClass\('error'\)/)
  end

end
