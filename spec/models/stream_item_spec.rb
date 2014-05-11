require_relative '../spec_helper'

describe StreamItem do

  before do
    @person = FactoryGirl.create(:person)
    @group = FactoryGirl.create(:group)
    @group.memberships.create! person: @person
  end

  describe 'Note' do
    it "should create a shared stream item when the note is on a group" do
      @note = FactoryGirl.create(:note, group: @group, person: @person)
      items = StreamItem.where(streamable_type: "Note", streamable_id: @note.id).to_a
      expect(items.length).to eq(1)
      expect(items.first).to be_shared
    end

    it "should create a shared stream item when the note is not on a group and the note's owner is sharing their activity" do
      @note = FactoryGirl.create(:note, person: @person)
      items = StreamItem.where(streamable_type: "Note", streamable_id: @note.id).to_a
      expect(items.length).to eq(1)
      expect(items.first).to be_shared
    end

    it "should create a non-shared stream item if the note is not on a group and the note's owner is not sharing their activity" do
      @person.update_attributes! share_activity: false
      @note = FactoryGirl.create(:note, person: @person)
      items = StreamItem.where(streamable_type: "Note", streamable_id: @note.id).to_a
      expect(items.length).to eq(1)
      expect(items.first).to_not be_shared
    end

    it "should delete all associated stream items when the note is deleted" do
      @note = FactoryGirl.create(:note, person: @person)
      items = StreamItem.where(streamable_type: "Note", streamable_id: @note.id).to_a
      expect(items.length).to eq(1)
      @note.destroy
      items = StreamItem.where(streamable_type: "Note", streamable_id: @note.id).to_a
      expect(items.length).to eq(0)
    end
  end

  describe 'NewsItem' do
    it "should create a shared stream item" do
      @news_item = FactoryGirl.create(:news_item, person: @person)
      items = StreamItem.where(streamable_type: "NewsItem", streamable_id: @news_item.id).to_a
      expect(items.length).to eq(1)
      expect(items.first).to be_shared
    end

    it "should delete all associated stream items when the news item is deleted" do
      @news_item = FactoryGirl.create(:news_item, person: @person)
      items = StreamItem.where(streamable_type: "NewsItem", streamable_id: @news_item.id).to_a
      expect(items.length).to eq(1)
      @news_item.destroy
      items = StreamItem.where(streamable_type: "NewsItem", streamable_id: @news_item.id).to_a
      expect(items.length).to eq(0)
    end
  end

  describe 'Picture' do
    it "should create a shared Album stream item for a new picture when the picture's album is in a group" do
      @album = FactoryGirl.create(:album, owner: @group)
      @picture = FactoryGirl.create(:picture, album: @album, person: @person)
      items = StreamItem.where(streamable_type: "Album", streamable_id: @album.id).to_a
      expect(items.length).to eq(1)
      expect(items.first).to be_shared
    end

    it "should create a shared Album stream item for a new picture when the pictures's album is not in a group and the owner is sharing their activity" do
      @album = FactoryGirl.create(:album, owner: @person)
      @picture = FactoryGirl.create(:picture, album: @album, person: @person)
      items = StreamItem.where(streamable_type: "Album", streamable_id: @album.id).to_a
      expect(items.length).to eq(1)
      expect(items.first).to be_shared
    end


    it "should create a non-shared stream item if the picture's album is not on a group and the owner is not sharing their activity" do
      @person.update_attributes! share_activity: false
      @album = FactoryGirl.create(:album, owner: @person)
      @picture = FactoryGirl.create(:picture, album: @album, person: @person)
      items = StreamItem.where(streamable_type: "Album", streamable_id: @album.id).to_a
      expect(items.length).to eq(1)
      expect(items.first).to_not be_shared
    end

    it "should add to the context of the previous stream_item when contiguous pictures are added" do
      @album = FactoryGirl.create(:album, owner: @person)
      @picture1 = FactoryGirl.create(:picture, album: @album, person: @person)
      items = StreamItem.where(streamable_type: "Album", streamable_id: @album.id).to_a
      expect(items.length).to eq(1)
      expect(items.first.context["picture_ids"]).to eq([[@picture1.id, @picture1.photo.fingerprint, @picture1.photo_extension]])
      @picture2 = FactoryGirl.create(:picture, album: @album, person: @person)
      items = StreamItem.where(streamable_type: "Album", streamable_id: @album.id).to_a
      expect(items.length).to eq(1)
      expect(items.first.context["picture_ids"]).to eq([[@picture1.id, @picture1.photo.fingerprint, @picture1.photo_extension], [@picture2.id, @picture2.photo.fingerprint, @picture2.photo_extension]])
    end

    it "should update the context of all associated stream items when the picture is deleted" do
      @album = FactoryGirl.create(:album, owner: @person)
      @picture1 = FactoryGirl.create(:picture, album: @album, person: @person)
      @picture2 = FactoryGirl.create(:picture, album: @album, person: @person)
      @picture1.destroy
      items = StreamItem.where(streamable_type: "Album", streamable_id: @album.id).to_a
      expect(items.length).to eq(1)
      expect(items.first.context["picture_ids"]).to eq([[@picture2.id, @picture2.photo.fingerprint, @picture2.photo_extension]])
    end

    it "should delete the album stream item if the last picture in the context is deleted" do
      @album = FactoryGirl.create(:album, owner: @person)
      @picture1 = FactoryGirl.create(:picture, album: @album, person: @person)
      @picture2 = FactoryGirl.create(:picture, album: @album, person: @person)
      items = StreamItem.where(streamable_type: "Album", streamable_id: @album.id).to_a
      expect(items.length).to eq(1)
      @picture1.destroy
      @picture2.destroy
      items = StreamItem.where(streamable_type: "Album", streamable_id: @album.id).to_a
      expect(items.length).to eq(0)
    end
  end

  describe 'Album' do
    it "should delete all associated stream items when the album is deleted" do
      @album = FactoryGirl.create(:album, owner: @person)
      @picture = FactoryGirl.create(:picture, album: @album, person: @person)
      items = StreamItem.where(streamable_type: "Album", streamable_id: @album.id).to_a
      expect(items.length).to eq(1)
      @album.destroy
      items = StreamItem.where(streamable_type: "Album", streamable_id: @album.id).to_a
      expect(items.length).to eq(0)
    end
  end

end
