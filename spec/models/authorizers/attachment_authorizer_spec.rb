require_relative '../../rails_helper'

describe AttachmentAuthorizer do
  before do
    @user = FactoryGirl.create(:person)
  end

  context 'on a message' do
    before do
      @message = FactoryGirl.create(:message, :with_attachment)
      @attachment = @message.attachments.first
    end

    it 'should not delete attachment' do
      expect(@user).to_not be_able_to(:delete, @attachment)
    end

    context 'user is owner of message' do
      before do
        @message.update_attributes!(person: @user)
      end

      it 'should delete attachment' do
        expect(@user).to be_able_to(:delete, @attachment)
      end
    end

    context 'user is admin with manage_groups privilege' do
      before do
        @user.update_attributes!(admin: Admin.create!(manage_groups: true))
      end

      it 'should not delete attachment' do
        expect(@user).to_not be_able_to(:delete, @attachment)
      end
    end

    # on a message that's on a group, yay!
    context 'on a group' do
      before do
        @group = FactoryGirl.create(:group)
        @message.update_attributes!(group: @group)
      end

      context 'user is group member' do
        before do
          @group.memberships.create(person: @user)
        end

        it 'should not delete attachment' do
          expect(@user).to_not be_able_to(:delete, @attachment)
        end
      end

      context 'user is group admin' do
        before do
          @group.memberships.create(person: @user, admin: true)
        end

        it 'should delete attachment' do
          expect(@user).to be_able_to(:delete, @attachment)
        end
      end
    end
  end
end
