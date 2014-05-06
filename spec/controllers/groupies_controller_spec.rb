require_relative '../spec_helper'

describe GroupiesController do

  before do
    @group = FactoryGirl.create(:group, category: 'Small Groups')
    15.times { @group.memberships.create!(person: FactoryGirl.create(:person)) }
    @person = @group.people.last
  end

  it "should show all groupies" do
    get :index, {person_id: @person.id}, {logged_in_id: @person.id}
    expect(assigns(:people).length).to eq(14)
  end

end
