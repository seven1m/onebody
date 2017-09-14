require 'rails_helper'

describe CheckinPresenter do
  let(:person) { FactoryGirl.create(:person) }

  subject { CheckinPresenter.new('Main', person.family) }

  before do
    Time.zone = 'America/Chicago'
  end

  describe '#times' do
    context 'given a recurring time in the morning' do
      let!(:checkin_time) { FactoryGirl.create(:checkin_time, time: '9:00 am') }

      context 'queried in the morning' do
        before do
          Timecop.freeze(Time.local(2014, 7, 6, 8, 0o0))
        end

        it 'returns the recurring time' do
          expect(subject.times.to_a).to eq([checkin_time])
        end
      end

      context 'queried at night' do
        before do
          Timecop.freeze(Time.local(2014, 7, 6, 23, 0o0))
        end

        # TODO: we probably should *not* be returning times that have passed,
        # but for now, this is how it works
        it 'returns the recurring time' do
          expect(subject.times.to_a).to eq([checkin_time])
        end
      end

      context 'queried the day after' do
        before do
          Timecop.freeze(Time.local(2014, 7, 7, 9, 0o0))
        end

        it 'returns nothing' do
          expect(subject.times.to_a).to eq([])
        end
      end
    end

    context 'given a recurring time at night' do
      let!(:checkin_time) { FactoryGirl.create(:checkin_time, time: '11:30 pm') }

      context 'queried in the morning' do
        before do
          Timecop.freeze(Time.local(2014, 7, 6, 9, 0o0))
        end

        it 'returns the recurring time' do
          expect(subject.times.to_a).to eq([checkin_time])
        end
      end

      context 'queried at night' do
        before do
          Timecop.freeze(Time.local(2014, 7, 6, 23, 0o0))
        end

        it 'returns the recurring time' do
          expect(subject.times.to_a).to eq([checkin_time])
        end
      end

      context 'queried the day after' do
        before do
          Timecop.freeze(Time.local(2014, 7, 7, 9, 0o0))
        end

        it 'returns nothing' do
          expect(subject.times.to_a).to eq([])
        end
      end
    end
  end

  describe '#selections' do
    let!(:group1)        { FactoryGirl.create(:group) }
    let!(:group2)        { FactoryGirl.create(:group) }
    let!(:checkin_time1) { FactoryGirl.create(:checkin_time, weekday: Time.current.wday, time: '9:00 am') }
    let!(:checkin_time2) { FactoryGirl.create(:checkin_time, weekday: Time.current.wday, time: '10:30 am') }
    let!(:group_time1)   { checkin_time1.group_times.create!(group: group1) }
    let!(:folder)        { FactoryGirl.create(:checkin_folder, checkin_time: checkin_time2) }
    let!(:group_time2)   { folder.group_times.create!(group: group2) }

    let!(:attendance1) do
      FactoryGirl.create(
        :attendance_record,
        person:       person,
        checkin_time: checkin_time1,
        group:        group1,
        attended_at:  checkin_time1.to_time
      )
    end

    let!(:attendance2) do
      FactoryGirl.create(
        :attendance_record,
        person:       person,
        checkin_time: checkin_time2,
        group:        group2,
        attended_at:  checkin_time2.to_time
      )
    end

    it 'returns current selections' do
      expect(subject.selections).to match(
        person.id => {
          checkin_time1.id => include(
            'id'                  => group_time1.id,
            'group_id'            => group1.id,
            'checkin_time_id'     => checkin_time1.id,
            'print_extra_nametag' => false,
            'checkin_folder_id'   => nil,
            'label_id'            => nil,
            group: {
              name: group1.name
            }
          ),
          checkin_time2.id => include(
            'id'                  => group_time2.id,
            'group_id'            => group2.id,
            'checkin_time_id'     => nil,
            'print_extra_nametag' => false,
            'checkin_folder_id'   => folder.id,
            'label_id'            => nil,
            group: {
              name: group2.name
            }
          )
        }
      )
    end
  end
end
