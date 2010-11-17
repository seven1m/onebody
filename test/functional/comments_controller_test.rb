require File.dirname(__FILE__) + '/../test_helper'

class CommentsControllerTest < ActionController::TestCase

  def setup
    @person = Person.forge
  end

  should "add a comment to a verse" do
    @verse = Verse.forge
    num_comments = Comment.count
    post :create, {:text => 'dude', :verse_id => @verse.id}, {:logged_in_id => @person.id}
    assert_response :redirect
    assert_equal num_comments + 1, Comment.count
  end

  should "add a comment to a recipe" do
    @recipe = Recipe.forge
    num_comments = Comment.count
    post :create, {:text => 'dude', :recipe_id => @recipe.id}, {:logged_in_id => @person.id}
    assert_response :redirect
    assert_equal num_comments + 1, Comment.count
  end

  should "add a comment to a note" do
    @note = @person.forge(:note)
    num_comments = Comment.count
    post :create, {:text => 'dude', :note_id => @note.id}, {:logged_in_id => @person.id}
    assert_response :redirect
    assert_equal num_comments + 1, Comment.count
  end

  should "delete a comment" do
    @comment = @person.forge(:comment)
    post :destroy, {:id => @comment.id}, {:logged_in_id => @person.id}
    assert_response :redirect
    assert_raise(ActiveRecord::RecordNotFound) do
      @comment.reload
    end
  end

  should "not delete a comment unless user is owner or admin" do
    @comment = @person.forge(:comment)
    @other_person = Person.forge
    post :destroy, {:id => @comment.id}, {:logged_in_id => @other_person.id}
    assert_response :unauthorized
  end

end
