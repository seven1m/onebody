require File.dirname(__FILE__) + '/../test_helper'

class VersesControllerTest < ActionController::TestCase

  def setup
    @person, @other_person = Person.forge, Person.forge
    2.times { @person.verses       << Verse.forge(:tag_list => 'foo bar') }
    2.times { @other_person.verses << Verse.forge(:tag_list => 'baz foo') }
    @verse = Verse.first
  end
  
  should "show a paginated listing of all verses with a tag cloud" do
    get :index, nil, {:logged_in_id => @person.id}
    assert_response :success
    assert_equal 4, assigns(:verses).length
    assert_equal 3, assigns(:tags).length
  end
  
  should "show one verse" do
    get :show, {:id => @verse.id}, {:logged_in_id => @person.id}
    assert_response :success
    assert_select 'h1', Regexp.new(@verse.reference)
  end
  
  should "tag a verse" do
    assert_equal 2, @verse.tag_list.length
    # add just 1
    get :update, {:id => @verse.id, :add_tags => 'new'}, {:logged_in_id => @person.id}
    assert_redirected_to verse_path(@verse)
    assert_equal 3, @verse.reload.tag_list.length
    # add 2 more
    get :update, {:id => @verse.id, :add_tags => 'two more'}, {:logged_in_id => @person.id}
    assert_redirected_to verse_path(@verse)
    assert_equal 5, @verse.reload.tag_list.length
  end
  
  should "remove a tag from a verse" do
    assert_equal 2, @verse.tag_list.length
    # remove 1
    get :update, {:id => @verse.id, :remove_tag => 'foo'}, {:logged_in_id => @person.id}
    assert_redirected_to verse_path(@verse)
    assert_equal 1, @verse.reload.tag_list.length
  end
  
  should "add a verse (to the user)" do
    @verse.people.delete @person
    assert !@person.verses.include?(@verse)
    post :create, {:id => @verse.id}, {:logged_in_id => @person.id}
    assert_redirected_to verse_path(@verse)
    assert @person.verses.include?(@verse)
  end
  
  should "remove a verse (from the user)" do
    @verse.people << @other_person
    assert_equal 2, @verse.people.count
    assert @verse.people.include?(@person)
    post :destroy, {:id => @verse.id}, {:logged_in_id => @person.id}
    assert_redirected_to verse_path(@verse)
    assert !@verse.people.include?(@person)
  end
  
  should "destroy the verse if there are no more people" do
    post :destroy, {:id => @verse.id}, {:logged_in_id => @person.id}
    assert_redirected_to verses_path
    assert_raise(ActiveRecord::RecordNotFound) do
      @verse.reload
    end
  end

end
