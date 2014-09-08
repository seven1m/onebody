require 'spec_helper'

describe Task do
  before do
    @group = FactoryGirl.create(:group)
    @person = FactoryGirl.create(:person)
    @task = FactoryGirl.create(:task, name: "Do stuff", group: @group, person: @person)
  end

  it "should have a name" do
    expect(@task.name).to eq("Do stuff")
  end
end
