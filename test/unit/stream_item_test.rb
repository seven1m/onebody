require File.dirname(__FILE__) + '/../test_helper'

class StreamItemTest < ActiveSupport::TestCase
  
  context 'Note' do
    should "create a stream item if the note is on a group"
    should "create a stream item if the note's owner is sharing their activity"
    should "not create a stream item if the note is not on a group and the note's owner is not sharing their activity"
    should "delete all associated stream items when the note is deleted"
  end
  
  context 'NewsItem' do
    should "create a stream item"
    should "delete all associated stream items when the news item is deleted"
  end
  
  context 'Picture' do
    should "create a stream item if the picture's album is on a group"
    should "create a stream item if the pictures's owner is sharing their activity"
    should "not create a stream item if the picture's album is not on a group and the picture's owner is not sharing their activity"
    should "update the context of all associated stream items when the picture is deleted"
  end
  
  context 'Album' do
    should "delete all associated stream items when the album is deleted"
  end
  
  context 'Verse' do
    should "create a stream item if the person is sharing their activity"
    should "not create a stream item if the person is not sharing their activity"
    should "delete all associated stream items when the verse is removed from the person"
  end
  
end
