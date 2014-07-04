require_relative '../spec_helper'

describe CheckinPresenter do

  let(:person) { FactoryGirl.create(:person) }

  subject { CheckinPresenter.new('Broken Arrow', person) }

  describe '#times' do
    context 'given a recurring time in the morning' do
      let!(:checkin_time) { FactoryGirl.create(:checkin_time, :recurring, time: '9:00 am') }

      context 'queried in the morning' do
        before do
          Timecop.freeze(Time.local(2014, 7, 6, 8, 00))
        end

        it 'returns the recurring time' do
          expect(subject.times.to_a).to eq([checkin_time])
        end
      end

      context 'queried at night' do
        before do
          Timecop.freeze(Time.local(2014, 7, 6, 23, 00))
        end

        # TODO we probably should *not* be returning times that have passed,
        # but for now, this is how it works
        it 'returns the recurring time' do
          expect(subject.times.to_a).to eq([checkin_time])
        end
      end

      context 'queried the day after' do
        before do
          Timecop.freeze(Time.local(2014, 7, 7, 9, 00))
        end

        it 'returns nothing' do
          expect(subject.times.to_a).to eq([])
        end
      end
    end

    context 'given a recurring time at night' do
      let!(:checkin_time) { FactoryGirl.create(:checkin_time, :recurring, time: '11:30 pm') }

      context 'queried in the morning' do
        before do
          Timecop.freeze(Time.local(2014, 7, 6, 9, 00))
        end

        it 'returns the recurring time' do
          expect(subject.times.to_a).to eq([checkin_time])
        end
      end

      context 'queried at night' do
        before do
          Timecop.freeze(Time.local(2014, 7, 6, 23, 00))
        end

        it 'returns the recurring time' do
          expect(subject.times.to_a).to eq([checkin_time])
        end
      end

      context 'queried the day after' do
        before do
          Timecop.freeze(Time.local(2014, 7, 7, 9, 00))
        end

        it 'returns nothing' do
          expect(subject.times.to_a).to eq([])
        end
      end
    end
  end

end
