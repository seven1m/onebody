require File.dirname(__FILE__) + '/../test_helper'

class VerseTest < Test::Unit::TestCase
  fixtures :verses
  
  def setup
    @verse = Verse.create(:reference => 'John 3:16', :text => 'test')
  end

  should "find an existing verse by reference" do
    v = Verse.find(@verse.reference)
    assert_equal 'test', v.text
  end
  
  should "find an existing verse by id" do
    v = Verse.find(@verse.id)
    assert_equal 'test', v.text
  end
  
  should "create a verse by reference" do
    v = Verse.find('1 John 1:9')
    assert_equal 'test', v.text
  end
end
