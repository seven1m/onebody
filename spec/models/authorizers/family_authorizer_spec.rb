require 'rails_helper'

describe FamilyAuthorizer do
  before do
    @user = FactoryGirl.create(:person)
  end

  describe 'family' do
    it 'should update own family' do
      expect(@user).to be_able_to(:update, @user.family)
    end

    it 'should not update a stranger family' do
      @stranger = FactoryGirl.create(:person)
      expect(@user).to_not be_able_to(:update, @stranger.family)
    end

    it 'should not update deleted family' do
      @deleted = FactoryGirl.create(:family, deleted: true)
      expect(@user).to_not be_able_to(:update, @deleted)
    end

    context 'user is not an adult' do
      before do
        @user.update_attributes!(child: true)
      end

      it 'should not update family' do
        expect(@user).to_not be_able_to(:update, @user.family)
      end
    end

    context 'user is admin with edit_profiles privilege' do
      before do
        @user.update_attributes!(admin: Admin.create!(edit_profiles: true))
      end

      it 'should update a stranger family' do
        @stranger = FactoryGirl.create(:person)
        expect(@user).to be_able_to(:update, @stranger.family)
      end

      it 'should update a deleted person' do
        @deleted = FactoryGirl.create(:family, deleted: true)
        expect(@user).to be_able_to(:update, @deleted)
      end

      it 'should delete stranger' do
        @stranger = FactoryGirl.create(:person)
        expect(@user).to be_able_to(:delete, @stranger.family)
      end

      it 'should create new family' do
        expect(@user).to be_able_to(:create, Family)
      end

      context 'family is not visible' do
        before do
          @hidden = FactoryGirl.create(:family, visible: false)
        end

        it 'should not update family' do
          expect(@user).to_not be_able_to(:update, @hidden)
        end

        it 'should not delete family' do
          expect(@user).to_not be_able_to(:delete, @hidden)
        end

        context 'admin has view_hidden_profiles privilege' do
          before do
            @user.admin.update_attributes!(view_hidden_profiles: true)
          end

          it 'should update family' do
            expect(@user).to be_able_to(:update, @hidden)
          end

          it 'should delete family' do
            expect(@user).to be_able_to(:delete, @hidden)
          end
        end
      end
    end

    it 'should not delete self' do
      expect(@user).to_not be_able_to(:delete, @user.family)
    end

    it 'should not create new family' do
      expect(@user).to_not be_able_to(:create, Family)
    end
  end
end
