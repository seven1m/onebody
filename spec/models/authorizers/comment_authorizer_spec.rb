require 'rails_helper'

describe CommentAuthorizer do
  before do
    @user = FactoryGirl.create(:person)
    @comment = FactoryGirl.create(
      :comment,
      person: FactoryGirl.create(:person),
      commentable: FactoryGirl.create(:verse)
    )
  end

  it 'should not update comment' do
    expect(@user).to_not be_able_to(:update, @comment)
  end

  it 'should not delete comment' do
    expect(@user).to_not be_able_to(:delete, @comment)
  end

  context 'owned by user' do
    before do
      @comment.update_attributes!(person: @user)
    end

    it 'should update comment' do
      expect(@user).to be_able_to(:update, @comment)
    end

    it 'should delete comment' do
      expect(@user).to be_able_to(:delete, @comment)
    end
  end

  context 'user is admin with manage_comments privilege' do
    before do
      @user.update_attributes!(admin: Admin.create!(manage_comments: true))
    end

    it 'should update comment' do
      expect(@user).to be_able_to(:update, @comment)
    end

    it 'should delete comment' do
      expect(@user).to be_able_to(:delete, @comment)
    end
  end
end
