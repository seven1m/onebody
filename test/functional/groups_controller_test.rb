require_relative '../test_helper'

class GroupsControllerTest < ActionController::TestCase

  def setup
    @person, @other_person = FactoryGirl.create_list(:person, 2)
    @group = FactoryGirl.create(:group, creator: @person, category: 'Small Groups')
    @group.memberships.create(person: @person, admin: true)
  end

  should "show a group" do
    get :show, {id: @group.id}, {logged_in_id: @person.id}
    assert_response :success
    assert_tag tag: 'h2', content: Regexp.new(@group.name)
  end

  should "not show a group if group is private and user is not a member of the group" do
    @private_group = FactoryGirl.create(:group, private: true)
    get :show, {id: @private_group.id}, {logged_in_id: @person.id}
    assert_response :missing
  end

  should "not show a group if it is hidden" do
    @hidden_group = FactoryGirl.create(:group, hidden: true)
    get :show, {id: @hidden_group.id}, {logged_in_id: @person.id}
    assert_response :missing
  end

  should "show a hidden group if the user can manage groups" do
    @hidden_group = FactoryGirl.create(:group, hidden: true)
    @admin = FactoryGirl.create(:person, admin: Admin.create(manage_groups: true))
    get :show, {id: @hidden_group.id}, {logged_in_id: @admin.id}
    assert_response :success
    assert_tag tag: 'h2', content: Regexp.new(@hidden_group.name)
  end

  should "list a person's groups" do
    get :index, {person_id: @person.id}, {logged_in_id: @person.id}
    assert_response :success
    assert_equal 1, assigns(:person).groups.length
  end

  should "not list a person's hidden groups" do
    @group.update_attribute :hidden, true
    get :index, {person_id: @person.id}, {logged_in_id: @person.id}
    assert_no_tag tag: 'tr', attributes: {class: 'grayed hidden-group'}
  end

  should "list a person's hidden groups if the user can manage groups" do
    @admin = FactoryGirl.create(:person, admin: Admin.create(manage_groups: true))
    @group.update_attribute :hidden, true
    get :index, {person_id: @person.id}, {logged_in_id: @admin.id}
    assert_tag tag: 'tr', attributes: {class: 'grayed hidden-group'}
  end

  should "search for groups by name" do
    FactoryGirl.create(:group, name: 'foo')
    get :index, {name: 'foo'}, {logged_in_id: @person.id}
    assert_equal 1, assigns(:groups).length
  end

  should "search for groups by category" do
    get :index, {category: 'Small Groups'}, {logged_in_id: @person.id}
    assert_equal 2, assigns(:groups).length
  end

  should "list a person's unapproved groups" do
    Group.delete_all
    @group = FactoryGirl.create(:group, creator_id: @person.id, approved: false)
    @group.memberships.create(person: @person, admin: true)
    2.times { FactoryGirl.create(:group, approved: false) }
    get :index, nil, {logged_in_id: @person.id}
    assert_equal 1, assigns(:unapproved_groups).length
  end

  should "list all unapproved groups if the user can manage groups" do
    @admin = FactoryGirl.create(:person, admin: Admin.create(manage_groups: true))
    Group.delete_all
    2.times { FactoryGirl.create(:group, approved: false) }
    get :index, nil, {logged_in_id: @admin.id}
    assert_equal 2, assigns(:unapproved_groups).length
  end

  should "add a group photo" do
    @group.photo = nil
    assert !@group.photo.exists?
    post :update, {id: @group.id, group: {photo: Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/image.jpg'), 'image/jpeg', true)}}, {logged_in_id: @person.id}
    assert_redirected_to group_path(@group)
    assert Group.find(@group.id).photo.exists?
  end

  should "remove a group photo" do
    @group.photo = File.open(Rails.root.join('test/fixtures/files/image.jpg'))
    @group.save!
    assert @group.photo.exists?
    post :update, {id: @group.id, group: {photo: 'remove'}}, {logged_in_id: @person.id}
    assert_redirected_to group_path(@group)
    assert !Group.find(@group.id).photo.exists?
  end

  should "edit a group" do
    get :edit, {id: @group.id}, {logged_in_id: @person.id}
    assert_response :success
    post :update, {id: @group.id, group: {name: 'test name', category: 'test cat'}}, {logged_in_id: @person.id}
    assert_redirected_to group_path(@group)
    assert_equal 'test name', @group.reload.name
    assert_equal 'test cat',  @group.category
  end

  should "not edit a group unless user is group admin or can manage groups" do
    get :edit, {id: @group.id}, {logged_in_id: @other_person.id}
    assert_response :unauthorized
    post :update, {id: @group.id, group: {name: 'test name', category: 'test cat'}}, {logged_in_id: @other_person.id}
    assert_response :unauthorized
  end

  should "create a group pending approval" do
    get :new, nil, {logged_in_id: @person.id}
    assert_response :success
    group_count = Group.count
    post :create, {group: {name: 'test name', category: 'test cat'}}, {logged_in_id: @person.id}
    assert_response :redirect
    assert_equal group_count+1, Group.count
    new_group = Group.last
    assert_equal 'test name', new_group.name
    assert_equal 'test cat',  new_group.category
    assert !new_group.approved?
  end

  should "create an approved group if user can manage groups" do
    @admin = FactoryGirl.create(:person, admin: Admin.create(manage_groups: true))
    get :new, nil, {logged_in_id: @admin.id}
    assert_response :success
    group_count = Group.count
    post :create, {group: {name: 'test name', category: 'test cat'}}, {logged_in_id: @admin.id}
    assert_response :redirect
    assert_equal group_count+1, Group.count
    new_group = Group.last
    assert_equal 'test name', new_group.name
    assert_equal 'test cat',  new_group.category
    assert new_group.approved?
  end

  should "not allow creation of groups if the site has reached limit" do
    Site.current.update_attribute(:max_groups, 1000)
    post :create, {group: {name: 'test name 1', category: 'test cat 1'}}, {logged_in_id: @person.id}
    assert_response :redirect
    Site.current.update_attribute(:max_groups, 1)
    post :create, {group: {name: 'test name 2', category: 'test cat 2'}}, {logged_in_id: @person.id}
    assert_response :unauthorized
    Site.current.update_attribute(:max_groups, nil)
    post :create, {group: {name: 'test name 3', category: 'test cat 3'}}, {logged_in_id: @person.id}
    assert_response :redirect
  end

  should "batch edit groups" do
    @admin = FactoryGirl.create(:person, admin: Admin.create(manage_groups: true))
    @group2 = FactoryGirl.create(:group)
    get :batch, nil, {logged_in_id: @admin.id}
    assert_response :success
    assert_template :batch
    # regular post
    post :batch, {groups: {@group.id.to_s => {name: "foobar", members_send: "0"}, @group2.id.to_s => {address: 'baz'}}}, {logged_in_id: @admin.id}
    assert_response :success
    assert_template :batch
    assert_equal 'foobar', @group.reload.name
    assert !@group.members_send?
    assert_equal 'baz', @group2.reload.address
    # ajax post
    post :batch, {format: 'js', groups: {@group.id.to_s => {name: "lorem", members_send: "true"}, @group2.id.to_s => {address: 'ipsum'}}}, {logged_in_id: @admin.id}
    assert_response :success
    assert_template :batch
    assert_equal 'lorem', @group.reload.name
    assert @group.members_send?
    assert_equal 'ipsum', @group2.reload.address
  end

  should 'report errors when batch editing groups' do
    @admin = FactoryGirl.create(:person, admin: Admin.create(manage_groups: true))
    # regular post
    post :batch, {groups: {@group.id.to_s => {address: "bad*address"}}}, {logged_in_id: @admin.id}
    assert_response :success
    assert_template :batch
    assert_select "#group#{@group.id} .errors", I18n.t('activerecord.errors.models.group.attributes.address.invalid')
    # ajax post
    post :batch, {format: 'js', groups: {@group.id.to_s => {address: "bad*address"}}}, {logged_in_id: @admin.id}
    assert_response :success
    assert_template :batch
    assert_match /\$\("#group#{@group.id}"\)\.addClass\('error'\)/, @response.body
  end

end
