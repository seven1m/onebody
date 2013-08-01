require_relative '../../test_helper'

class FamilyAuthorizerTest < ActiveSupport::TestCase

  setup do
    @user = FactoryGirl.create(:person)
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

      should 'delete stranger' do
        @stranger = FactoryGirl.create(:person)
        assert_can @user, :delete, @stranger.family
      end

      should 'create new family' do
        assert_can @user, :create, Family
      end

      context 'family is not visible' do
        setup do
          @hidden = FactoryGirl.create(:family, visible: false)
        end

        should 'not update family' do
          assert_cannot @user, :update, @hidden
        end

        should 'not delete family' do
          assert_cannot @user, :delete, @hidden
        end

        context 'admin has view_hidden_profiles privilege' do
          setup do
            @user.admin.update_attributes!(view_hidden_profiles: true)
          end

          should 'update family' do
            assert_can @user, :update, @hidden
          end

          should 'delete family' do
            assert_can @user, :delete, @hidden
          end
        end
      end
    end

    should 'not delete self' do
      assert_cannot @user, :delete, @user.family
    end

    should 'not create new family' do
      assert_cannot @user, :create, Family
    end
  end

end
