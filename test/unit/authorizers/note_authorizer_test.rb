require_relative '../../test_helper'

class NoteAuthorizerTest < ActiveSupport::TestCase

  setup do
    @user = FactoryGirl.create(:person)
    @note = FactoryGirl.create(:note)
  end

  should 'read note' do
    assert_can @user, :read, @note
  end

  should 'not create note' do
    assert_cannot @user, :create, @note
  end

  should 'not update note' do
    assert_cannot @user, :update, @note
  end

  should 'not delete note' do
    assert_cannot @user, :delete, @note
  end

  context 'owned by user' do
    setup do
      @note.update_attributes!(person: @user)
    end

    should 'create note' do
      assert_can @user, :create, @note
    end

    should 'update note' do
      assert_can @user, :update, @note
    end

    should 'delete note' do
      assert_can @user, :delete, @note
    end
  end

  context 'user is admin with manage_notes privilege' do
    setup do
      @user.update_attributes!(admin: Admin.create!(manage_notes: true))
    end

    should 'create note' do
      assert_can @user, :create, @note
    end

    should 'update note' do
      assert_can @user, :update, @note
    end

    should 'delete note' do
      assert_can @user, :delete, @note
    end
  end

  context 'note is in a group' do
    setup do
      @group = FactoryGirl.create(:group)
      @note.update_attributes!(group: @group)
    end

    should 'see note' do
      assert_can @user, :read, @note
    end

    should 'not create note' do
      assert_cannot @user, :create, @note
    end

    context 'group is hidden' do
      setup do
        @group.update_attributes!(hidden: true)
      end

      should 'not see note' do
        assert_cannot @user, :read, @note
      end

      should 'not create note' do
        assert_cannot @user, :create, @note
      end

      context 'user is a group member' do
        setup do
          @group.memberships.create!(person: @user)
        end

        should 'read note' do
          assert_can @user, :read, @note
        end

        should 'create note' do
          assert_can @user, :create, @note
        end
      end
    end

    context 'group is private' do
      setup do
        @group.update_attributes!(private: true)
      end

      should 'not see note' do
        assert_cannot @user, :read, @note
      end

      should 'not create note' do
        assert_cannot @user, :create, @note
      end

      context 'user is a group member' do
        setup do
          @group.memberships.create!(person: @user)
        end

        should 'read note' do
          assert_can @user, :read, @note
        end

        should 'create note' do
          assert_can @user, :create, @note
        end
      end
    end
  end

  context 'note is owned by an invisible person' do
    setup do
      @note.person.update_attributes!(visible: false)
    end

    should 'not read note' do
      assert_cannot @user, :read, @note
    end

    context 'note is in a group' do
      setup do
        @group = FactoryGirl.create(:group)
        @note.update_attributes!(group: @group)
      end

      should 'read note' do
        assert_can @user, :read, @note
      end

      should 'not update note' do
        assert_cannot @user, :update, @note
      end

      context 'group is hidden' do
        setup do
          @group.update_attributes!(hidden: true)
        end

        should 'not read note' do
          assert_cannot @user, :read, @note
        end

        context 'user is a group member' do
          setup do
            @group.memberships.create!(person: @user)
          end

          should 'read note' do
            assert_can @user, :read, @note
          end
        end
      end
    end
  end

end
