require File.dirname(__FILE__) + '/abstract_unit'

class TagListTest < ActiveSupport::TestCase
  def test_from_leaves_string_unchanged
    tags = '"One  ", Two'
    original = tags.dup
    TagList.from(tags)
    assert_equal tags, original
  end
  
  def test_from_single_name
    assert_equal %w(Fun), TagList.from("Fun")
    assert_equal %w(Fun), TagList.from('"Fun"')
  end
  
  def test_from_blank
    assert_equal [], TagList.from(nil)
    assert_equal [], TagList.from("")
  end
  
  def test_from_single_quoted_tag
    assert_equal ['with, comma'], TagList.from('"with, comma"')
  end
  
  def test_spaces_do_not_delineate
    assert_equal ['A B', 'C'], TagList.from('A B, C')
  end
  
  def test_from_multiple_tags
    assert_equivalent %w(Alpha Beta Delta Gamma), TagList.from("Alpha, Beta, Delta, Gamma")
  end
  
  def test_from_multiple_tags_with_quotes
    assert_equivalent %w(Alpha Beta Delta Gamma), TagList.from('Alpha,  "Beta",  Gamma , "Delta"')
  end
  
  def test_from_with_single_quotes
    assert_equivalent ['A B', 'C'], TagList.from("'A B', C")
  end
  
  def test_from_multiple_tags_with_quote_and_commas
    assert_equivalent ['Alpha, Beta', 'Delta', 'Gamma, something'], TagList.from('"Alpha, Beta", Delta, "Gamma, something"')
  end
  
  def test_from_with_inner_quotes
    assert_equivalent ["House", "Drum 'n' Bass", "Trance"], TagList.from("House, Drum 'n' Bass, Trance")
    assert_equivalent ["House", "Drum'n'Bass", "Trance"], TagList.from("House, Drum'n'Bass, Trance")
  end
  
  def test_from_removes_white_space
    assert_equivalent %w(Alpha Beta), TagList.from('" Alpha   ", "Beta  "')
    assert_equivalent %w(Alpha Beta), TagList.from('  Alpha,  Beta ')
  end
  
  def test_from_and_new_treat_both_accept_arrays
    tags = ["One", "Two"]
    
    assert_equal TagList.from(tags), TagList.new(tags)
  end
  
  def test_alternative_delimiter
    TagList.delimiter = " "
    
    assert_equal %w(One Two), TagList.from("One Two")
    assert_equal ['One two', 'three', 'four'], TagList.from('"One two" three four')
  ensure
    TagList.delimiter = ","
  end
  
  def test_duplicate_tags_removed
    assert_equal %w(One), TagList.from("One, One")
  end
  
  def test_to_s_with_commas
    assert_equal "Question, Crazy Animal", TagList.new("Question", "Crazy Animal").to_s
  end
  
  def test_to_s_with_alternative_delimiter
    TagList.delimiter = " "
    
    assert_equal '"Crazy Animal" Question', TagList.new("Crazy Animal", "Question").to_s
  ensure
    TagList.delimiter = ","
  end
  
  def test_add
    tag_list = TagList.new("One")
    assert_equal %w(One), tag_list
    
    assert_equal %w(One Two), tag_list.add("Two")
    assert_equal %w(One Two Three), tag_list.add(["Three"])
  end
  
  def test_remove
    tag_list = TagList.new("One", "Two")
    assert_equal %w(Two), tag_list.remove("One")
    assert_equal %w(), tag_list.remove(["Two"])
  end
  
  def test_new_with_parsing
    assert_equal %w(One Two), TagList.new("One, Two", :parse => true)
  end
  
  def test_add_with_parsing
    assert_equal %w(One Two), TagList.new.add("One, Two", :parse => true)
  end
  
  def test_remove_with_parsing
    tag_list = TagList.from("Three, Four, Five")
    assert_equal %w(Four), tag_list.remove("Three, Five", :parse => true)
  end
  
  def test_toggle
    tag_list = TagList.new("One", "Two")
    assert_equal %w(One Three), tag_list.toggle("Two", "Three")
    assert_equal %w(), tag_list.toggle("One", "Three")
    assert_equal %w(Four), tag_list.toggle("Four")
  end
end
