require_relative '../../rails_helper'

describe Checkin::GroupsController, type: :controller do
  let!(:checkin_time)   { FactoryGirl.create(:checkin_time) }
  let!(:checkin_folder) { FactoryGirl.create(:checkin_folder, checkin_time: checkin_time) }
  let!(:group1)         { FactoryGirl.create(:group, name: 'Check-in Group 1') }
  let!(:group2)         { FactoryGirl.create(:group, name: 'Check-in Group 2') }
  let!(:group_time1)    { checkin_time.group_times.create!(group: group1) }
  let!(:group_time2)    { checkin_folder.group_times.create!(group: group2) }
  let!(:user)           { FactoryGirl.create(:person) }

  describe '#index' do
    before do
      get :index, { date: '2015-03-22', format: :json }, logged_in_id: user.id
    end

    it 'returns group info' do
      expect(response).to be_success
      data = JSON.parse(response.body)
      expect(data).to include(
        'groups' => {
          '09:00 AM' => {
            'Adult Classes' => [
              [group2.id, 'Check-in Group 2', false, nil, 'Adult Classes']
            ],
            '' => [
              [group1.id, 'Check-in Group 1', false, nil, nil]
            ]
          }
        },
        'updated_at' => instance_of(String)
      )
    end
  end
end
