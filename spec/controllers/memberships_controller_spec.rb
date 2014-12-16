require_relative '../rails_helper'

describe MembershipsController, type: :controller do

  before do
    @admin = FactoryGirl.create(:person, admin: Admin.create!(edit_profiles: true, manage_groups: true))
    @person = FactoryGirl.create(:person)
    @group1 = FactoryGirl.create(:group)
    @group2 = FactoryGirl.create(:group)
    @person.memberships.create!(group: @group1)
  end

  it "should add/remote group memberships" do
    post :batch, {ids: [@group2.id], person_id: @person.id, format: :js}, {logged_in_id: @admin.id}
    expect(response).to be_success
    expect(@person.reload.groups.to_a).to eq([@group2])
  end

end
