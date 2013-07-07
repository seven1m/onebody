require_relative '../test_helper'

class AbilityTest < ActiveSupport::TestCase

  setup do
    @user = FactoryGirl.create(:person)
  end

  context 'user has account frozen' do
    setup do
      @user.update_attributes!(account_frozen: true)
    end

    should 'read self' do
      assert_can @user, :read, @user
    end

    should 'not update self' do
      assert_cannot @user, :update, @user
    end

    should 'not update family' do
      assert_cannot @user, :update, @user.family
    end
  end

  context 'family' do
    should 'update own family' do
      assert_can @user, :update, @user.family
    end

    should 'not update a stranger family' do
      @stranger = FactoryGirl.create(:person)
      assert_cannot @user, :update, @stranger.family
    end

    should 'not update deleted family' do
      @deleted = FactoryGirl.create(:family, deleted: true)
      assert_cannot @user, :update, @deleted
    end

    context 'user is not an adult' do
      setup do
        @user.update_attributes!(child: true)
      end

      should 'not update family' do
        assert_cannot @user, :update, @user.family
      end
    end

    context 'user is admin with edit_profiles privilege' do
      setup do
        @user.update_attributes!(admin: Admin.create!(edit_profiles: true))
      end

      should 'update a stranger family' do
        @stranger = FactoryGirl.create(:person)
        assert_can @user, :update, @stranger.family
      end

      should 'update a deleted person' do
        @deleted = FactoryGirl.create(:family, deleted: true)
        assert_can @user, :update, @deleted
      end

      should 'destroy stranger' do
        @stranger = FactoryGirl.create(:person)
        assert_can @user, :destroy, @stranger.family
      end

      should 'create new family' do
        assert_can @user, :create, Family
      end
    end

    should 'not destroy self' do
      assert_cannot @user, :destroy, @user.family
    end

    should 'not create new family' do
      assert_cannot @user, :create, Family
    end
  end

  context 'picture' do
    setup do
      @picture = FactoryGirl.create(:picture)
    end

    should 'not update picture' do
      assert_cannot @user, :update, @picture
    end

    should 'not destroy picture' do
      assert_cannot @user, :destroy, @picture
    end

    context 'owned by user' do
      setup do
        @picture.update_attributes!(person: @user)
      end

      should 'update picture' do
        assert_can @user, :update, @picture
      end

      should 'destroy picture' do
        assert_can @user, :destroy, @picture
      end
    end

    context 'picture in album in group' do
      setup do
        @group = FactoryGirl.create(:group)
        @picture.album.update_attributes!(owner: @group)
      end

      context 'user is group member' do
        setup do
          @group.memberships.create(person: @user)
        end

        should 'not update picture' do
          assert_cannot @user, :update, @picture
        end

        should 'not destroy picture' do
          assert_cannot @user, :destroy, @picture
        end
      end

      context 'user is group admin' do
        setup do
          @group.memberships.create(person: @user, admin: true)
        end

        should 'update picture' do
          assert_can @user, :update, @picture
        end

        should 'destroy picture' do
          assert_can @user, :destroy, @picture
        end
      end
    end

    context 'user is admin with manage_pictures privilege' do
      setup do
        @user.update_attributes!(admin: Admin.create!(manage_pictures: true))
      end

      should 'update picture' do
        assert_can @user, :update, @picture
      end

      should 'destroy picture' do
        assert_can @user, :destroy, @picture
      end
    end
  end

  context 'message' do
    setup do
      @message = FactoryGirl.create(:message)
    end

    should 'not update message' do
      assert_cannot @user, :update, @message
    end

    should 'not destroy message' do
      assert_cannot @user, :destroy, @message
    end

    context 'owned by user' do
      setup do
        @message.update_attributes!(person: @user)
      end

      should 'update message' do
        assert_can @user, :update, @message
      end

      should 'destroy message' do
        assert_can @user, :destroy, @message
      end
    end

    context 'message is not in a group' do
      context 'user is admin with manage_groups privilege' do
        setup do
          @user.update_attributes!(admin: Admin.create!(manage_groups: true))
        end

        should 'not update message' do
          assert_cannot @user, :update, @message
        end

        should 'not destroy message' do
          assert_cannot @user, :destroy, @message
        end
      end
    end

    context 'message in a group' do
      setup do
        @group = FactoryGirl.create(:group)
        @message.update_attributes!(group: @group)
      end

      should 'not update message' do
        assert_cannot @user, :update, @message
      end

      should 'not destroy message' do
        assert_cannot @user, :destroy, @message
      end

      context 'user is admin with manage_groups privilege' do
        setup do
          @user.update_attributes!(admin: Admin.create!(manage_groups: true))
        end

        should 'update message' do
          assert_can @user, :update, @message
        end

        should 'destroy message' do
          assert_can @user, :destroy, @message
        end
      end

      context 'user is group admin' do
        setup do
          @group.memberships.create(person: @user, admin: true)
        end

        should 'update message' do
          assert_can @user, :update, @message
        end

        should 'destroy message' do
          assert_can @user, :destroy, @message
        end
      end
    end
  end

  context 'prayer request' do
    setup do
      @prayer_request = FactoryGirl.create(:prayer_request)
      @group = @prayer_request.group
    end

    should 'not update prayer request' do
      assert_cannot @user, :update, @prayer_request
    end

    should 'not destroy prayer request' do
      assert_cannot @user, :destroy, @prayer_request
    end

    context 'owned by user' do
      setup do
        @prayer_request.update_attributes!(person: @user)
      end

      should 'update prayer request' do
        assert_can @user, :update, @prayer_request
      end

      should 'destroy prayer request' do
        assert_can @user, :destroy, @prayer_request
      end
    end

    context 'user is admin with manage_groups privilege' do
      setup do
        @user.update_attributes!(admin: Admin.create!(manage_groups: true))
      end

      should 'update prayer request' do
        assert_can @user, :update, @prayer_request
      end

      should 'destroy prayer request' do
        assert_can @user, :destroy, @prayer_request
      end
    end

    context 'user is group member' do
      setup do
        @group.memberships.create(person: @user)
      end

      should 'not update prayer request' do
        assert_cannot @user, :update, @prayer_request
      end

      should 'not destroy prayer request' do
        assert_cannot @user, :destroy, @prayer_request
      end
    end

    context 'user is group admin' do
      setup do
        @group.memberships.create(person: @user, admin: true)
      end

      should 'update prayer request' do
        assert_can @user, :update, @prayer_request
      end

      should 'destroy prayer request' do
        assert_can @user, :destroy, @prayer_request
      end
    end
  end

  context 'comment' do
    setup do
      @comment = FactoryGirl.create(:comment)
    end

    should 'not update comment' do
      assert_cannot @user, :update, @comment
    end

    should 'not destroy comment' do
      assert_cannot @user, :destroy, @comment
    end

    context 'owned by user' do
      setup do
        @comment.update_attributes!(person: @user)
      end

      should 'update comment' do
        assert_can @user, :update, @comment
      end

      should 'destroy comment' do
        assert_can @user, :destroy, @comment
      end
    end

    context 'user is admin with manage_comments privilege' do
      setup do
        @user.update_attributes!(admin: Admin.create!(manage_comments: true))
      end

      should 'update comment' do
        assert_can @user, :update, @comment
      end

      should 'destroy comment' do
        assert_can @user, :destroy, @comment
      end
    end
  end

  context 'page' do
    setup do
      @page = FactoryGirl.create(:page)
    end

    should 'not update page' do
      assert_cannot @user, :update, @page
    end

    should 'not destroy page' do
      assert_cannot @user, :destroy, @page
    end

    context 'user is admin with edit_pages privilege' do
      setup do
        @user.update_attributes!(admin: Admin.create!(edit_pages: true))
      end

      should 'update page' do
        assert_can @user, :update, @page
      end

      should 'destroy page' do
        assert_can @user, :destroy, @page
      end
    end
  end

  context 'attachment' do
    context 'on a message' do
      setup do
        @message = FactoryGirl.create(:message, :with_attachment)
        @attachment = @message.attachments.first
      end

      should 'not destroy attachment' do
        assert_cannot @user, :destroy, @attachment
      end

      context 'user is owner of message' do
        setup do
          @message.update_attributes!(person: @user)
        end

        should 'destroy attachment' do
          assert_can @user, :destroy, @attachment
        end
      end

      context 'user is admin with manage_groups privilege' do
        setup do
          @user.update_attributes!(admin: Admin.create!(manage_groups: true))
        end

        should 'not destroy attachment' do
          assert_cannot @user, :destroy, @attachment
        end
      end

      # on a message that's on a group, yay!
      context 'on a group' do
        setup do
          @group = FactoryGirl.create(:group)
          @message.update_attributes!(group: @group)
        end

        context 'user is group member' do
          setup do
            @group.memberships.create(person: @user)
          end

          should 'not destroy attachment' do
            assert_cannot @user, :destroy, @attachment
          end
        end

        context 'user is group admin' do
          setup do
            @group.memberships.create(person: @user, admin: true)
          end

          should 'destroy attachment' do
            assert_can @user, :destroy, @attachment
          end
        end
      end
    end

    context 'on a group' do
      setup do
        @group = FactoryGirl.create(:group)
        @attachment = @group.attachments.create!
      end

      context 'user is admin with manage_groups privilege' do
        setup do
          @user.update_attributes!(admin: Admin.create!(manage_groups: true))
        end

        should 'destroy attachment' do
          assert_can @user, :destroy, @attachment
        end
      end

      context 'user is group member' do
        setup do
          @group.memberships.create(person: @user)
        end

        should 'not destroy attachment' do
          assert_cannot @user, :destroy, @attachment
        end
      end

      context 'user is group admin' do
        setup do
          @group.memberships.create(person: @user, admin: true)
        end

        should 'destroy attachment' do
          assert_can @user, :destroy, @attachment
        end
      end
    end
  end

  context 'news item' do
    setup do
      @news_item = FactoryGirl.create(:news_item)
    end

    should 'not update news item' do
      assert_cannot @user, :update, @news_item
    end

    should 'not destroy news item' do
      assert_cannot @user, :destroy, @news_item
    end

    context 'user is owner of news item' do
      setup do
        @news_item.update_attributes!(person: @user)
      end

      should 'destroy news item' do
        assert_can @user, :destroy, @news_item
      end
    end

    context 'user is admin with manage_news privilege' do
      setup do
        @user.update_attributes!(admin: Admin.create!(manage_news: true))
      end

      should 'update news item' do
        assert_can @user, :update, @news_item
      end

      should 'destroy news item' do
        assert_can @user, :destroy, @news_item
      end
    end
  end

  context 'group membership' do
    setup do
      @group = FactoryGirl.create(:group)
      @membership = @group.memberships.create!
    end

    should 'not update membership' do
      assert_cannot @user, :update, @membership
    end

    should 'not destroy membership' do
      assert_cannot @user, :destroy, @membership
    end

    context 'owned by user' do
      setup do
        @membership.update_attributes!(person: @user)
      end

      should 'update membership' do
        assert_can @user, :update, @membership
      end

      should 'destroy membership' do
        assert_can @user, :destroy, @membership
      end
    end

    context 'user is admin with manage_groups privilege' do
      setup do
        @user.update_attributes!(admin: Admin.create!(manage_groups: true))
      end

      should 'update membership' do
        assert_can @user, :update, @membership
      end

      should 'destroy membership' do
        assert_can @user, :destroy, @membership
      end
    end

    context 'user is admin with edit_profiles privilege' do
      setup do
        @user.update_attributes!(admin: Admin.create!(edit_profiles: true))
      end

      should 'update membership' do
        assert_can @user, :update, @membership
      end

      should 'destroy membership' do
        assert_can @user, :destroy, @membership
      end
    end

    context 'user is group admin' do
      setup do
        @group.memberships.create(person: @user, admin: true)
      end

      should 'update membership' do
        assert_can @user, :update, @membership
      end

      should 'destroy membership' do
        assert_can @user, :destroy, @membership
      end
    end

    context 'user is family member' do
      setup do
        @spouse = FactoryGirl.create(:person, family: @user.family)
        @membership.update_attributes!(person: @spouse)
      end

      should 'update membership' do
        assert_can @user, :update, @membership
      end

      should 'destroy membership' do
        assert_can @user, :destroy, @membership
      end

      context 'user is child' do
        setup do
          @user.update_attributes!(child: true)
        end

        should 'not update membership' do
          assert_cannot @user, :update, @membership
        end

        should 'not destroy membership' do
          assert_cannot @user, :destroy, @membership
        end
      end
    end
  end
end
