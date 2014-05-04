require_relative '../../test_helper'

class AttachmentAuthorizerTest < ActiveSupport::TestCase

  setup do
    @user = FactoryGirl.create(:person)
  end

  context 'on a message' do
    setup do
      @message = FactoryGirl.create(:message, :with_attachment)
      @attachment = @message.attachments.first
    end

    should 'not delete attachment' do
      assert_cannot @user, :delete, @attachment
    end

    context 'user is owner of message' do
      setup do
        @message.update_attributes!(person: @user)
      end

      should 'delete attachment' do
        assert_can @user, :delete, @attachment
      end
    end

    context 'user is admin with manage_groups privilege' do
      setup do
        @user.update_attributes!(admin: Admin.create!(manage_groups: true))
      end

      should 'not delete attachment' do
        assert_cannot @user, :delete, @attachment
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

        should 'not delete attachment' do
          assert_cannot @user, :delete, @attachment
        end
      end

      context 'user is group admin' do
        setup do
          @group.memberships.create(person: @user, admin: true)
        end

        should 'delete attachment' do
          assert_can @user, :delete, @attachment
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

      should 'delete attachment' do
        assert_can @user, :delete, @attachment
      end
    end

    context 'user is group member' do
      setup do
        @group.memberships.create(person: @user)
      end

      should 'not delete attachment' do
        assert_cannot @user, :delete, @attachment
      end
    end

    context 'user is group admin' do
      setup do
        @group.memberships.create(person: @user, admin: true)
      end

      should 'delete attachment' do
        assert_can @user, :delete, @attachment
      end
    end
  end

end
