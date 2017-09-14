require 'rails_helper'

describe AttendanceRecord, type: :model do
  before do
    @attendance_record = FactoryGirl.create(:attendance_record)
  end

  context '#group' do
    context 'attendance record group is empty' do
      before do
        @attendance_record.group = nil
      end

      it 'should be invalid' do
        expect(@attendance_record).to be_invalid
      end
    end
  end

  context '#attended_at' do
    context 'attendance record #attended_at is empty' do
      before do
        @attendance_record.attended_at = nil
      end

      it 'should be invalid' do
        expect(@attendance_record).to be_invalid
      end
    end
  end
end
