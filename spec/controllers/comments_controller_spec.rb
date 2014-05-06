require_relative '../spec_helper'

describe CommentsController do

  before do
    @person = FactoryGirl.create(:person)
  end

  it "should add a comment to a verse" do
    @verse = FactoryGirl.create(:verse)
    num_comments = Comment.count
    post :create, {text: 'dude', verse_id: @verse.id}, {logged_in_id: @person.id}
    expect(response).to be_redirect
    expect(Comment.count).to eq(num_comments + 1)
  end

  it "should add a comment to a note" do
    @note = FactoryGirl.create(:note, person: @person)
    num_comments = Comment.count
    post :create, {text: 'dude', note_id: @note.id}, {logged_in_id: @person.id}
    expect(response).to be_redirect
    expect(Comment.count).to eq(num_comments + 1)
  end

  it "should delete a comment" do
    @comment = FactoryGirl.create(:comment, person: @person)
    post :destroy, {id: @comment.id}, {logged_in_id: @person.id}
    expect(response).to be_redirect
    assert_raise(ActiveRecord::RecordNotFound) do
      @comment.reload
    end
  end

  it "should not delete a comment unless user is owner or admin" do
    @comment = FactoryGirl.create(:comment, person: @person)
    @other_person = FactoryGirl.create(:person)
    post :destroy, {id: @comment.id}, {logged_in_id: @other_person.id}
    expect(response).to be_unauthorized
  end

end
