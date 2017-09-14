require 'rails_helper'

describe Stats::AttendanceGraphPresenter do
  describe '#data' do
    let!(:attendance_record) do
      FactoryGirl.create(:attendance_record, attended_at: 1.day.ago.strftime('%Y-%m-%d %H:%M:%S'))
    end

    it 'returns an array of 30 counts' do
      expect(subject.data).to eq([
                                   0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                   0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                                   0, 0, 0, 0, 0, 0, 0, 0, 1, 0
                                 ])
    end
  end
end
