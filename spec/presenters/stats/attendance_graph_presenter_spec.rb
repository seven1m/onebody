require_relative '../../rails_helper'

describe Stats::AttendanceGraphPresenter do
  describe '#data' do
    it 'returns an array of 30 counts' do
      expect(subject.data).to eq([0] * 30)
    end
  end
end
