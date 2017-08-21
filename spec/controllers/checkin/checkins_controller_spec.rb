require_relative '../../rails_helper'

describe Checkin::CheckinsController, type: :controller do
  let(:user) { FactoryGirl.create(:person, :admin_manage_checkin) }

  before do
    Setting.set(:features, :checkin, true)
    Timecop.freeze(Time.local(2014, 6, 29, 8, 0o0))
  end

  after { Timecop.return }

  describe '#update' do
    let!(:time)       { FactoryGirl.create(:checkin_time) }
    let!(:person)     { FactoryGirl.create(:person) }
    let!(:group)      { FactoryGirl.create(:group) }
    let!(:group_time) { time.group_times.create!(group: group) }

    let!(:existing) do
      person.attendance_records.create!(
        group: group,
        attended_at: DateTime.new(2014, 6, 29, 9, 0, 0)
      )
    end

    before do
      patch :update,
            params: {
              people: {
                person.id => {
                  time.id => {
                    id: group_time.id
                  }
                },
                'Tim Morgan' => {
                  time.id => {
                    id: group_time.id
                  }
                }
              }
            },
            session: { barcode: '1111111111',
                       checkin_logged_in_id: user.id }
    end

    it 'creates a new attendance record for members and for guests' do
      expect(AttendanceRecord.count).to eq(2)
      expect(AttendanceRecord.all.map(&:attributes)).to match_array([
                                                                      include(
                                                                        'person_id'   => person.id,
                                                                        'attended_at' => DateTime.new(2014, 6, 29, 9, 0, 0),
                                                                        'barcode_id'  => '1111111111'
                                                                      ),
                                                                      include(
                                                                        'person_id'   => nil,
                                                                        'first_name'  => 'Tim',
                                                                        'last_name'   => 'Morgan',
                                                                        'attended_at' => DateTime.new(2014, 6, 29, 9, 0, 0),
                                                                        'barcode_id'  => '1111111111'
                                                                      )
                                                                    ])
    end

    it 'deletes existing records for the same time' do
      expect { existing.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
