require 'rails_helper'
require 'ostruct'

describe StreamItemGrouper, type: :model do
  describe StreamItemGrouper::Grouper do
    context 'given a list of items, all shared' do
      subject do
        described_class.new([
                              OpenStruct.new(id: 1, shared: true),
                              OpenStruct.new(id: 2, shared: true),
                              OpenStruct.new(id: 3, shared: true),
                              OpenStruct.new(id: 4, shared: true)
                            ])
      end

      describe '#grouped' do
        it 'returns all but the latest 2 items' do
          expect(subject.grouped).to eq([
                                          OpenStruct.new(id: 1, shared: true),
                                          OpenStruct.new(id: 2, shared: true)
                                        ])
        end
      end

      describe '#exposed' do
        it 'returns the last 2 items' do
          expect(subject.exposed).to eq([
                                          OpenStruct.new(id: 3, shared: true),
                                          OpenStruct.new(id: 4, shared: true)
                                        ])
        end
      end
    end

    context 'given a list of items, some recent non-shared' do
      subject do
        described_class.new([
                              OpenStruct.new(id: 1, shared: true),
                              OpenStruct.new(id: 2, shared: true),
                              OpenStruct.new(id: 3, shared: false),
                              OpenStruct.new(id: 4, shared: true)
                            ])
      end

      describe '#grouped' do
        it 'returns all but the last 2 items, but does not include non-shared items' do
          expect(subject.grouped).to eq([
                                          OpenStruct.new(id: 1, shared: true)
                                        ])
        end
      end

      describe '#exposed' do
        it 'returns the last 2 items plus any items that are non-shared' do
          expect(subject.exposed).to eq([
                                          OpenStruct.new(id: 2, shared: true),
                                          OpenStruct.new(id: 3, shared: false),
                                          OpenStruct.new(id: 4, shared: true)
                                        ])
        end
      end
    end

    context 'given a list of items, some older non-shared' do
      subject do
        described_class.new([
                              OpenStruct.new(id: 1, shared: false),
                              OpenStruct.new(id: 2, shared: true),
                              OpenStruct.new(id: 3, shared: true),
                              OpenStruct.new(id: 4, shared: true)
                            ])
      end

      describe '#grouped' do
        it 'returns all but the last 2 items, but does not include non-shared items' do
          expect(subject.grouped).to eq([
                                          OpenStruct.new(id: 2, shared: true)
                                        ])
        end
      end

      describe '#exposed' do
        it 'returns the last 2 items plus any items that are non-shared' do
          expect(subject.exposed).to eq([
                                          OpenStruct.new(id: 1, shared: false),
                                          OpenStruct.new(id: 3, shared: true),
                                          OpenStruct.new(id: 4, shared: true)
                                        ])
        end
      end
    end
  end

  def create_stream_items(items)
    created_at = 1.hour.ago
    items.each_with_index.map do |item, index|
      created_at += 1.minute
      StreamItem.create!(
        title:           "item #{index}",
        streamable_type: 'Person',
        created_at:      created_at,
        shared:          item[:shared].nil? ? true : item[:shared]
      )
    end
  end

  describe '#group' do
    context 'given 5 Person stream items in a row' do
      let(:items) do
        create_stream_items([
                              { shared: true  },
                              { shared: true  },
                              { shared: false },
                              { shared: true  },
                              { shared: true  }
                            ])
      end

      before do
        described_class.new(items.last).group
      end

      it 'groups the first two and exposes the last two plus the not-shared one' do
        items = StreamItem.order(:created_at, id: :desc).all
        expect(items.size).to eq(6)
        group = StreamItem.groups.first
        expect(items.map(&:attributes)).to match([
                                                   include(
                                                     'title' => 'item 0',
                                                     'stream_item_group_id' => group.id,
                                                     'shared' => true
                                                   ),
                                                   include(
                                                     'title' => 'item 1',
                                                     'stream_item_group_id' => group.id,
                                                     'shared' => true
                                                   ),
                                                   include(
                                                     'title' => 'item 2',
                                                     'stream_item_group_id' => nil,
                                                     'shared' => false
                                                   ),
                                                   include(
                                                     'streamable_type' => 'StreamItemGroup',
                                                     'context' => {
                                                       streamable_type: 'Person'
                                                     },
                                                     'created_at' => items[-2].created_at - 1.second,
                                                     'shared' => true,
                                                     'is_public' => true
                                                   ),
                                                   include(
                                                     'title' => 'item 3',
                                                     'stream_item_group_id' => nil,
                                                     'shared' => true
                                                   ),
                                                   include(
                                                     'title' => 'item 4',
                                                     'stream_item_group_id' => nil,
                                                     'shared' => true
                                                   )
                                                 ])
      end

      context 'given the non-shared item becomes shared' do
        before do
          base_item = StreamItem.where(shared: false).first
          base_item.shared = true
          base_item.save!
          described_class.new(base_item).group
        end

        it 'gets added to the group' do
          items = StreamItem.order(:created_at, id: :desc).all
          expect(items.size).to eq(6)
          group = StreamItem.groups.first
          expect(items.map(&:attributes)).to match([
                                                     include(
                                                       'title' => 'item 0',
                                                       'stream_item_group_id' => group.id,
                                                       'shared' => true
                                                     ),
                                                     include(
                                                       'title' => 'item 1',
                                                       'stream_item_group_id' => group.id,
                                                       'shared' => true
                                                     ),
                                                     include(
                                                       'title' => 'item 2',
                                                       'stream_item_group_id' => group.id,
                                                       'shared' => true
                                                     ),
                                                     include(
                                                       'streamable_type' => 'StreamItemGroup',
                                                       'context' => {
                                                         streamable_type: 'Person'
                                                       },
                                                       'created_at' => items[-2].created_at - 1.second,
                                                       'shared' => true,
                                                       'is_public' => true
                                                     ),
                                                     include(
                                                       'title' => 'item 3',
                                                       'stream_item_group_id' => nil,
                                                       'shared' => true
                                                     ),
                                                     include(
                                                       'title' => 'item 4',
                                                       'stream_item_group_id' => nil,
                                                       'shared' => true
                                                     )
                                                   ])
        end
      end
    end

    context 'given only two of the items are shared' do
      let(:items) do
        create_stream_items([
                              { shared: true  },
                              { shared: false },
                              { shared: false },
                              { shared: true  },
                              { shared: false }
                            ])
      end

      before do
        described_class.new(items.last).group
      end

      it 'does not create a group' do
        items = StreamItem.order(:created_at, id: :desc).all
        expect(items.size).to eq(5)
        expect(StreamItem.groups.count).to eq(0)
      end
    end

    context 'given none of the items are shared' do
      let(:items) do
        create_stream_items([
                              { shared: false },
                              { shared: false },
                              { shared: false },
                              { shared: false },
                              { shared: false }
                            ])
      end

      before do
        described_class.new(items.last).group
      end

      it 'does not create a group' do
        items = StreamItem.order(:created_at, id: :desc).all
        expect(items.size).to eq(5)
        expect(StreamItem.groups.count).to eq(0)
      end
    end
  end
end
