require_relative '../rails_helper'

describe StreamItemGroupJob do
  before do
    allow(StreamItemGroupJob).to receive(:perform_later).and_call_original
  end

  describe '#perform' do
    context 'given 1 Person stream item' do
      let!(:person1) { FactoryGirl.create(:person, first_name: 'Aaron', created_at: 3.minutes.ago) }

      it 'does not create a new group' do
        expect(StreamItem.where(streamable_type: 'StreamItemGroup').count).to eq(0)
      end
    end

    context 'given 5 Person stream items in a row, interrupted by a news post, followed by 3 more' do
      let!(:person1) { FactoryGirl.create(:person, first_name: 'Aaron',  created_at: 9.minutes.ago) }
      let!(:person2) { FactoryGirl.create(:person, first_name: 'Bill',   created_at: 8.minutes.ago) }
      let!(:person3) { FactoryGirl.create(:person, first_name: 'Cole',   created_at: 7.minutes.ago) }
      let!(:person4) { FactoryGirl.create(:person, first_name: 'Dale',   created_at: 6.minutes.ago) }
      let!(:person5) { FactoryGirl.create(:person, first_name: 'Erwin',  created_at: 5.minutes.ago) }
      let!(:news)    { FactoryGirl.create(:news_item,                    published:  4.minutes.ago) }
      let!(:person6) { FactoryGirl.create(:person, first_name: 'Frank',  created_at: 3.minutes.ago) }
      let!(:person7) { FactoryGirl.create(:person, first_name: 'Gerard', created_at: 2.minutes.ago) }
      let!(:person8) { FactoryGirl.create(:person, first_name: 'Hal',    created_at: 1.minute.ago) }

      before do
        @group1, @group2 = StreamItem.where(streamable_type: 'StreamItemGroup').order(:created_at).to_a
      end

      it 'creates the group items' do
        expect(StreamItem.where(streamable_type: 'StreamItemGroup').count).to eq(2)
        expect(@group1.attributes).to include(
          'is_public' => true,
          'shared'    => true,
          'context'   => { streamable_type: 'Person' }
        )
        expect(@group1.items.to_a).to eq([person3.stream_item, person2.stream_item, person1.stream_item])
        expect(@group1.created_at).to eq(person1.reload.created_at)
        expect(@group2.items.to_a).to eq([person6.stream_item])
        expect(@group2.created_at).to eq(person6.reload.created_at)
      end
    end
  end
end
