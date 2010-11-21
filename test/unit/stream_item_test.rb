require File.dirname(__FILE__) + '/../test_helper'

class StreamItemTest < ActiveSupport::TestCase

  def setup
    @person = Person.forge
    @group = Group.forge
    @group.memberships.create! :person => @person
  end

  context 'Note' do
    should "create a shared stream item when the note is on a group" do
      @note = Note.forge(:group => @group, :person => @person)
      items = StreamItem.find_all_by_streamable_type_and_streamable_id('Note', @note.id)
      assert_equal 1, items.length
      assert items.first.shared?, 'StreamItem is not shared.'
    end

    should "create a shared stream item when the note is not on a group and the note's owner is sharing their activity" do
      @note = Note.forge(:person => @person)
      items = StreamItem.find_all_by_streamable_type_and_streamable_id('Note', @note.id)
      assert_equal 1, items.length
      assert items.first.shared?, 'StreamItem is not shared.'
    end

    should "create a non-shared stream item if the note is not on a group and the note's owner is not sharing their activity" do
      @person.update_attributes! :share_activity => false
      @note = Note.forge(:person => @person)
      items = StreamItem.find_all_by_streamable_type_and_streamable_id('Note', @note.id)
      assert_equal 1, items.length
      assert !items.first.shared?, 'StreamItem is shared.'
    end

    should "delete all associated stream items when the note is deleted" do
      @note = Note.forge(:person => @person)
      items = StreamItem.find_all_by_streamable_type_and_streamable_id('Note', @note.id)
      assert_equal 1, items.length
      @note.destroy
      items = StreamItem.find_all_by_streamable_type_and_streamable_id('Note', @note.id)
      assert_equal 0, items.length
    end
  end

  context 'NewsItem' do
    should "create a shared stream item" do
      @news_item = NewsItem.forge(:person => @person)
      items = StreamItem.find_all_by_streamable_type_and_streamable_id('NewsItem', @news_item.id)
      assert_equal 1, items.length
      assert items.first.shared?, 'StreamItem is not shared.'
    end

    should "delete all associated stream items when the news item is deleted" do
      @news_item = NewsItem.forge(:person => @person)
      items = StreamItem.find_all_by_streamable_type_and_streamable_id('NewsItem', @news_item.id)
      assert_equal 1, items.length
      @news_item.destroy
      items = StreamItem.find_all_by_streamable_type_and_streamable_id('NewsItem', @news_item.id)
      assert_equal 0, items.length
    end
  end

  context 'Picture' do
    should "create a shared Album stream item for a new picture when the picture's album is in a group" do
      @album = Album.forge(:group => @group, :person => @person)
      @picture = Picture.forge(:album => @album, :person => @person)
      items = StreamItem.find_all_by_streamable_type_and_streamable_id('Album', @album.id)
      assert_equal 1, items.length
      assert items.first.shared?, 'StreamItem is not shared.'
    end

    should "create a shared Album stream item for a new picture when the pictures's album is not in a group and the owner is sharing their activity" do
      @album = Album.forge(:person => @person)
      @picture = Picture.forge(:album => @album, :person => @person)
      items = StreamItem.find_all_by_streamable_type_and_streamable_id('Album', @album.id)
      assert_equal 1, items.length
      assert items.first.shared?, 'StreamItem is not shared.'
    end


    should "create a non-shared stream item if the picture's album is not on a group and the owner is not sharing their activity" do
      @person.update_attributes! :share_activity => false
      @album = Album.forge(:person => @person)
      @picture = Picture.forge(:album => @album, :person => @person)
      items = StreamItem.find_all_by_streamable_type_and_streamable_id('Album', @album.id)
      assert_equal 1, items.length
      assert !items.first.shared?, 'StreamItem is shared.'
    end

    should "add to the context of the previous stream_item when contiguous pictures are added" do
      @album = Album.forge(:person => @person)
      @picture1 = Picture.forge(:album => @album, :person => @person)
      items = StreamItem.find_all_by_streamable_type_and_streamable_id('Album', @album.id)
      assert_equal 1, items.length
      assert_equal [[@picture1.id, @picture1.photo.fingerprint, @picture1.photo_extension]], items.first.context['picture_ids']
      @picture2 = Picture.forge(:album => @album, :person => @person)
      items = StreamItem.find_all_by_streamable_type_and_streamable_id('Album', @album.id)
      assert_equal 1, items.length
      assert_equal [[@picture1.id, @picture1.photo.fingerprint, @picture1.photo_extension],
                    [@picture2.id, @picture2.photo.fingerprint, @picture2.photo_extension]], items.first.context['picture_ids']
    end

    should "update the context of all associated stream items when the picture is deleted" do
      @album = Album.forge(:person => @person)
      @picture1 = Picture.forge(:album => @album, :person => @person)
      @picture2 = Picture.forge(:album => @album, :person => @person)
      @picture1.destroy
      items = StreamItem.find_all_by_streamable_type_and_streamable_id('Album', @album.id)
      assert_equal 1, items.length
      assert_equal [[@picture2.id, @picture2.photo.fingerprint, @picture2.photo_extension]], items.first.context['picture_ids']
    end

    should "delete the album stream item if the last picture in the context is deleted" do
      @album = Album.forge(:person => @person)
      @picture1 = Picture.forge(:album => @album, :person => @person)
      @picture2 = Picture.forge(:album => @album, :person => @person)
      items = StreamItem.find_all_by_streamable_type_and_streamable_id('Album', @album.id)
      assert_equal 1, items.length
      @picture1.destroy
      @picture2.destroy
      items = StreamItem.find_all_by_streamable_type_and_streamable_id('Album', @album.id)
      assert_equal 0, items.length
    end
  end

  context 'Album' do
    should "delete all associated stream items when the album is deleted" do
      @album = Album.forge(:person => @person)
      @picture = Picture.forge(:album => @album, :person => @person)
      items = StreamItem.find_all_by_streamable_type_and_streamable_id('Album', @album.id)
      assert_equal 1, items.length
      @album.destroy
      items = StreamItem.find_all_by_streamable_type_and_streamable_id('Album', @album.id)
      assert_equal 0, items.length
    end
  end

end
