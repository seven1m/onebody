require_relative '../rails_helper'

describe StreamItem do
  before do
    @person = FactoryGirl.create(:person, created_at: 1.hour.ago)
    @group = FactoryGirl.create(:group, created_at: 1.hour.ago)
    @group.memberships.create! person: @person
  end

  describe 'NewsItem' do
    it 'should create a shared stream item' do
      @news_item = FactoryGirl.create(:news_item, person: @person)
      items = StreamItem.where(streamable_type: 'NewsItem', streamable_id: @news_item.id).to_a
      expect(items.length).to eq(1)
      expect(items.first).to be_shared
    end

    it 'should delete all associated stream items when the news item is deleted' do
      @news_item = FactoryGirl.create(:news_item, person: @person)
      items = StreamItem.where(streamable_type: 'NewsItem', streamable_id: @news_item.id).to_a
      expect(items.length).to eq(1)
      @news_item.destroy
      items = StreamItem.where(streamable_type: 'NewsItem', streamable_id: @news_item.id).to_a
      expect(items.length).to eq(0)
    end
  end

  describe 'Picture' do
    it "should create a shared Album stream item for a new picture when the picture's album is in a group" do
      @album = FactoryGirl.create(:album, owner: @group)
      @picture = FactoryGirl.create(:picture, album: @album, person: @person)
      items = StreamItem.where(streamable_type: 'Album', streamable_id: @album.id).to_a
      expect(items.length).to eq(1)
      expect(items.first).to be_shared
    end

    it "should create a shared Album stream item for a new picture when the pictures's album is not in a group and the owner is sharing their activity" do
      @album = FactoryGirl.create(:album, owner: @person)
      @picture = FactoryGirl.create(:picture, album: @album, person: @person)
      items = StreamItem.where(streamable_type: 'Album', streamable_id: @album.id).to_a
      expect(items.length).to eq(1)
      expect(items.first).to be_shared
    end

    it "should create a non-shared stream item if the picture's album is not on a group and the owner is not sharing their activity" do
      @person.update_attributes! share_activity: false
      @album = FactoryGirl.create(:album, owner: @person)
      @picture = FactoryGirl.create(:picture, album: @album, person: @person)
      items = StreamItem.where(streamable_type: 'Album', streamable_id: @album.id).to_a
      expect(items.length).to eq(1)
      expect(items.first).to_not be_shared
    end

    it 'should add to the context of the previous stream_item when contiguous pictures are added' do
      @album = FactoryGirl.create(:album, owner: @person)
      @picture1 = FactoryGirl.create(:picture, album: @album, person: @person)
      items = StreamItem.where(streamable_type: 'Album', streamable_id: @album.id).to_a
      expect(items.length).to eq(1)
      expect(items.first.context['picture_ids']).to eq([[@picture1.id, @picture1.photo.fingerprint, @picture1.photo_extension]])
      @picture2 = FactoryGirl.create(:picture, album: @album, person: @person)
      items = StreamItem.where(streamable_type: 'Album', streamable_id: @album.id).to_a
      expect(items.length).to eq(1)
      expect(items.first.context['picture_ids']).to eq([[@picture1.id, @picture1.photo.fingerprint, @picture1.photo_extension], [@picture2.id, @picture2.photo.fingerprint, @picture2.photo_extension]])
    end

    it 'should update the context of all associated stream items when the picture is deleted' do
      @album = FactoryGirl.create(:album, owner: @person)
      @picture1 = FactoryGirl.create(:picture, album: @album, person: @person)
      @picture2 = FactoryGirl.create(:picture, album: @album, person: @person)
      @picture1.destroy
      items = StreamItem.where(streamable_type: 'Album', streamable_id: @album.id).to_a
      expect(items.length).to eq(1)
      expect(items.first.context['picture_ids']).to eq([[@picture2.id, @picture2.photo.fingerprint, @picture2.photo_extension]])
    end

    it 'should delete the album stream item if the last picture in the context is deleted' do
      @album = FactoryGirl.create(:album, owner: @person)
      @picture1 = FactoryGirl.create(:picture, album: @album, person: @person)
      @picture2 = FactoryGirl.create(:picture, album: @album, person: @person)
      count = StreamItem.where(streamable_type: 'Album', streamable_id: @album.id).count
      expect(count).to eq(1)
      @picture1.destroy
      @picture2.destroy
      count = StreamItem.where(streamable_type: 'Album', streamable_id: @album.id).count
      expect(count).to eq(0)
    end
  end

  describe 'Album' do
    it 'should delete all associated stream items when the album is deleted' do
      @album = FactoryGirl.create(:album, owner: @person)
      @picture = FactoryGirl.create(:picture, album: @album, person: @person)
      items = StreamItem.where(streamable_type: 'Album', streamable_id: @album.id).to_a
      expect(items.length).to eq(1)
      @album.destroy
      items = StreamItem.where(streamable_type: 'Album', streamable_id: @album.id).to_a
      expect(items.length).to eq(0)
    end
  end

  describe '#shared_with' do
    context 'person' do
      let!(:album_item) { FactoryGirl.create(:stream_item, streamable_type: 'Album', person_id: @person.id, shared: true) }

      it 'does not share activity with a stranger' do
        stranger = FactoryGirl.create(:person)
        items = StreamItem.shared_with(stranger).where.not(streamable_type: %w(Person Site))
        expect(items).to be_empty
      end

      it 'shares activity with a family member' do
        spouse = FactoryGirl.create(:person, family: @person.family)
        items = StreamItem.shared_with(spouse).where.not(streamable_type: %w(Person Site))
        expect(items).to eq([album_item])
      end
    end

    context 'group' do
      let!(:album_item) { FactoryGirl.create(:stream_item, streamable_type: 'Album', person_id: @person.id, group_id: @group.id, shared: true) }

      it 'shares activity with a group member' do
        member = FactoryGirl.create(:person)
        @group.memberships.create! person: member
        items = StreamItem.shared_with(member).where.not(streamable_type: %w(Person Site))
        expect(items).to eq([album_item])
      end
    end
  end
end
