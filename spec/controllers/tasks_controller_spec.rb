require_relative '../rails_helper'

describe TasksController, type: :controller do

  before do
    @person, @other_person = FactoryGirl.create_list(:person, 2)
    @group, @other_group = FactoryGirl.create_list(:group, 2)
    @group.memberships.create(person_id: @person.id)
    @task = FactoryGirl.create(:task, group: @group, person: @person)
    @other_task = FactoryGirl.create(:task, group: @other_group, person: @other_person)
  end

  it "should list all the groups tasks" do
    get :index, {group_id: @group.id}, {logged_in_id: @person.id}
    expect(response).to be_success
    expect(assigns(:tasks).length).to eq(1)
  end

  it "should create a task" do
    @group.update_attribute(:has_tasks, true)
    get :new, {group_id: @group.id}, {logged_in_id: @person.id}
    expect(response).to be_success
    post :create, {group_id: @group.id, task: {person_id: @person.id, name: 'test task', description: 'test description', duedate: '1/1/2010'}}, {logged_in_id: @person.id}
    expect(response).to be_redirect
    new_task = Task.last
    expect(new_task.name).to eq("test task")
    expect(new_task.description).to eq("test description")
    expect(new_task.duedate.strftime("%m/%d/%Y")).to eq("01/01/2010")
  end
end
