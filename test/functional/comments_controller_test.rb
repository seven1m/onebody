require_relative '../test_helper'

class CommentsControllerTest < ActionController::TestCase

  def setup
    @person = FactoryGirl.create(:person)
  end

  should "add a comment to a verse" do
    @verse = FactoryGirl.create(:verse)
    num_comments = Comment.count
    post :create, {:text => 'dude', :verse_id => @verse.id}, {:logged_in_id => @person.id}
    assert_response :redirect
    assert_equal num_comments + 1, Comment.count
  end

  should "add a comment to a note" do
    @note = FactoryGirl.create(:note, :person => @person)
    num_comments = Comment.count
    post :create, {:text => 'dude', :note_id => @note.id}, {:logged_in_id => @person.id}
    assert_response :redirect
    assert_equal num_comments + 1, Comment.count
  end

  should "delete a comment" do
    @comment = FactoryGirl.create(:comment, :person => @person)
    post :destroy, {:id => @comment.id}, {:logged_in_id => @person.id}
    assert_response :redirect
    assert_raise(ActiveRecord::RecordNotFound) do
      @comment.reload
    end
  end

  should "not delete a comment unless user is owner or admin" do
    @comment = FactoryGirl.create(:comment, :person => @person)
    @other_person = FactoryGirl.create(:person)
    post :destroy, {:id => @comment.id}, {:logged_in_id => @other_person.id}
    assert_response :unauthorized
  end

end
