require 'rails_helper'

describe Task do
  before do
    @group = FactoryGirl.create(:group)
    @person = FactoryGirl.create(:person)
    @task = FactoryGirl.create(:task, name: "Do stuff", group: @group, person: @person)
  end

  it "should have a name" do
    expect(@task.name).to eq("Do stuff")
  end

  describe '.position' do
    context 'given a group with three tasks in it' do
      let!(:group) { FactoryGirl.create(:group) }
      let!(:task1)   { FactoryGirl.create(:task, group: group, name: "Task 1") }
      let!(:task2)   { FactoryGirl.create(:task, group: group, name: "Task 2") }
      let!(:task3)   { FactoryGirl.create(:task, group: group, name: "Task 3") }

      it 'can be reordered' do
        task1.insert_at(3)

        expect(task2.reload.position).to eq(1)
        expect(task3.reload.position).to eq(2)
        expect(task1.reload.position).to eq(3)
      end
    end
  end
end
