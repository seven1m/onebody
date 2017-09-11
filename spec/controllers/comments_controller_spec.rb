require_relative '../rails_helper'

describe CommentsController, type: :controller do
  before do
    @person = FactoryGirl.create(:person)
  end

  it 'should add a comment to a verse' do
    allow_any_instance_of(Verse).to receive(:lookup) do |i|
      i.translation = 'WEB'
      i.text = 'test'
      i.update_sortables
    end
    @verse = FactoryGirl.create(:verse)
    num_comments = Comment.count
    post :create,
         params: { comment: { text: 'dude', commentable_type: 'Verse', commentable_id: @verse.id } },
         session: { logged_in_id: @person.id }
    expect(response).to be_redirect
    expect(Comment.count).to eq(num_comments + 1)
  end

  it 'should delete a comment' do
    @comment = FactoryGirl.create(:comment, person: @person, commentable: FactoryGirl.create(:verse))
    post :destroy,
         params: { id: @comment.id },
         session: { logged_in_id: @person.id }
    expect(response).to be_redirect
    expect { @comment.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it 'should not delete a comment unless user is owner or admin' do
    @comment = FactoryGirl.create(:comment, person: @person, commentable: FactoryGirl.create(:verse))
    @other_person = FactoryGirl.create(:person)
    post :destroy,
         params: { id: @comment.id },
         session: { logged_in_id: @other_person.id }
    expect(response.status).to eq(401)
  end
end
