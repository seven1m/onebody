require_relative '../../../rails_helper'

describe 'Attendance Records API', type: :request do

  it 'should return a list of attendance records' do
    FactoryGirl.create_list(:attendance_record, 10)

    get "/api/v2/attendance-records"

    expect(response).to be_success
    expect(json_data.length).to eq(10)
  end

  it 'should retrieve a specific attendance record' do
    a_record = FactoryGirl.create(:attendance_record)

    get "/api/v2/attendance-records/#{a_record.id}"

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(a_record.id)
  end

  it 'should retrieve the person of an attendance record' do
    person = FactoryGirl.create(:person)
    a_record = FactoryGirl.create(:attendance_record, person: person)

    get "/api/v2/attendance-records/#{a_record.id}/person"

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(person.id)
  end

  it 'should rerieve the group of an attendance record' do
    group = FactoryGirl.create(:group)
    a_record = FactoryGirl.create(:attendance_record, group: group)

    get "/api/v2/attendance-records/#{a_record.id}/group"

    expect(response).to be_success
    expect(json_data['id'].to_i).to eq(group.id)
  end
end