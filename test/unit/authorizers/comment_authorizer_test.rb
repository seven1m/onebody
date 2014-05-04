require_relative '../../test_helper'

class CommentAuthorizerTest < ActiveSupport::TestCase

  setup do
    @user = FactoryGirl.create(:person)
    @comment = FactoryGirl.create(:comment)
  end

  should 'not update comment' do
    assert_cannot @user, :update, @comment
  end

  should 'not delete comment' do
    assert_cannot @user, :delete, @comment
  end

  context 'owned by user' do
    setup do
      @comment.update_attributes!(person: @user)
    end

    should 'update comment' do
      assert_can @user, :update, @comment
    end

    should 'delete comment' do
      assert_can @user, :delete, @comment
    end
  end

  context 'user is admin with manage_comments privilege' do
    setup do
      @user.update_attributes!(admin: Admin.create!(manage_comments: true))
    end

    should 'update comment' do
      assert_can @user, :update, @comment
    end

    should 'delete comment' do
      assert_can @user, :delete, @comment
    end
  end

end
