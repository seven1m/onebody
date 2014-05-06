require_relative '../spec_helper'

describe PrayerRequest do

  before do
    @group = FactoryGirl.create(:group)
    @person = FactoryGirl.create(:person)
    @req = FactoryGirl.create(:prayer_request, group: @group, person: @person)
  end

  it "should have a name" do
    expect(@req.name).to eq("Prayer Request in #{@group.name}")
  end

  it "should have a name with a question mark if the group doesn't exist" do
    @group.destroy # does not destroy child prayer requests
    @req.reload
    expect(@req.name).to eq("Prayer Request in ?")
  end

end
