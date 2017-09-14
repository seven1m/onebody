require 'rails_helper'

describe TasksController, type: :controller do
  before do
    @person, @other_person = FactoryGirl.create_list(:person, 2)
    @group, @other_group = FactoryGirl.create_list(:group, 2)
    @group.memberships.create(person_id: @person.id)
    @group.update_attribute(:has_tasks, true)
    @task = FactoryGirl.create(:task, group: @group, person: @person)
    @other_task = FactoryGirl.create(:task, group: @other_group, person: @other_person)
  end

  it 'should list all the groups tasks' do
    get :index,
        params: { group_id: @group.id },
        session: { logged_in_id: @person.id }
    expect(response).to be_success
    expect(assigns(:tasks).length).to eq(1)
  end

  it 'should create a task' do
    get :new,
        params: { group_id: @group.id },
        session: { logged_in_id: @person.id }
    expect(response).to be_success
    post :create,
         params: { group_id: @group.id, task:
                           { person_id: @person.id, name: 'test task',
                             description: 'test description', duedate: '1/1/2010' } },
         session: { logged_in_id: @person.id }
    expect(response).to be_redirect
    new_task = Task.last
    expect(new_task.name).to eq('test task')
    expect(new_task.description).to eq('test description')
    expect(new_task.duedate.strftime('%m/%d/%Y')).to eq('01/01/2010')
  end

  describe 'group_scope' do
    it 'should create a task, intended for the entire group' do
      post :create,
           params: { group_id: @group.id, task:
                               { person_id_or_all: 'All', name: 'everybodys taking a chance',
                                 description: 'men without hats', duedate: '1/4/2016' } },
           session: { logged_in_id: @person.id }
      expect(response).to be_redirect
      group_task = Task.last
      expect(group_task.group_scope).to be
    end
    it 'should create a task, assigned to a person' do
      post :create,
           params: { group_id: @group.id, task:
                               { person_id_or_all: @person.id, name: 'Little boy blue and the man',
                                 description: 'Harry Chapin', duedate: '1/4/2017' } },
           session: { logged_in_id: @person.id }
      person_id_or_all_as_person = Task.last
      expect(person_id_or_all_as_person.person_id).to eq(@person.id)
    end
  end
end
