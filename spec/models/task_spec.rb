require 'rails_helper'

describe Task, type: :model do
  before do
    @group = FactoryGirl.create(:group)
    @person = FactoryGirl.create(:person)
    @task = FactoryGirl.create(:task, name: 'Do stuff', group: @group, person: @person)
    @group_task = FactoryGirl.create(:task, name: 'Group work', group: @group, group_scope: true)
  end

  it 'should have a name' do
    expect(@task.name).to eq('Do stuff')
  end

  describe '.position' do
    context 'given a group with three tasks in it' do
      let!(:group) { FactoryGirl.create(:group) }
      let!(:task1)   { FactoryGirl.create(:task, group: group, name: 'Task 1') }
      let!(:task2)   { FactoryGirl.create(:task, group: group, name: 'Task 2') }
      let!(:task3)   { FactoryGirl.create(:task, group: group, name: 'Task 3') }

      it 'can be reordered' do
        task1.insert_at(3)

        expect(task2.reload.position).to eq(1)
        expect(task3.reload.position).to eq(2)
        expect(task1.reload.position).to eq(3)
      end
    end
  end

  describe '.group_scope' do
    it 'should return false when task is assigned' do
      expect(@task.group_scope).to be_falsey
    end
    it 'should return true when set' do
      expect(@group_task.group_scope).to be
    end
  end
end
