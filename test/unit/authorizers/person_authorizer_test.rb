require_relative '../../test_helper'

class PersonAuthorizerTest < ActiveSupport::TestCase

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
  end

  context 'given a stranger' do
    setup do
      @stranger = FactoryGirl.create(:person)
    end

    should 'read stranger' do
      assert_can @user, :read, @stranger
    end

    should 'not update a stranger' do
      assert_cannot @user, :update, @stranger
    end

    context 'stranger is deleted' do
      setup do
        @stranger.update_attributes!(deleted: true)
      end

      should 'not read stranger' do
        assert_cannot @user, :read, @stranger
      end
    end

    context 'stranger is not visible' do
      setup do
        @stranger.update_attributes!(visible: false)
      end

      should 'not read stranger' do
        assert_cannot @user, :read, @stranger
      end
    end

    context 'stranger is not marked visible_to_everyone' do
      setup do
        @stranger.update_attributes!(visible_to_everyone: false)
      end

      should 'not read stranger' do
        assert_cannot @user, :read, @stranger
      end
    end

    context 'stranger family is not visible' do
      setup do
        @stranger.family.update_attributes!(visible: false)
      end

      should 'not read stranger' do
        assert_cannot @user, :read, @stranger
      end
    end

    context 'stranger is a child' do
      setup do
        @stranger.update_attributes!(child: true)
      end

      should 'not read stranger' do
        assert_cannot @user, :read, @stranger
      end

      context 'child has parental consent' do
        setup do
          @stranger.update_attributes!(parental_consent: true)
        end

        should 'read stranger' do
          assert_can @user, :read, @stranger
        end
      end

      context 'user is admin with view_hidden_profiles privilege' do
        setup do
          @user.update_attributes!(admin: Admin.create!(view_hidden_profiles: true))
        end

        should 'read stranger' do
          assert_can @user, :read, @stranger
        end
      end
    end
  end

  should 'read self' do
    assert_can @user, :read, @user
  end

  should 'update self' do
    assert_can @user, :update, @user
  end

  context 'self is deleted' do
    setup do
      @user.update_attributes!(deleted: true)
    end

    should 'not read self' do
      assert_cannot  @user, :read, @user
    end
  end

  context 'family is deleted' do
    setup do
      @user.family.update_attributes!(deleted: true)
    end

    should 'not read self' do
      assert_cannot  @user, :read, @user
    end
  end

  context 'given another adult in the same family' do
    setup do
      @adult = FactoryGirl.create(:person, family: @user.family, child: false)
    end

    should 'read adult' do
      assert_can @user, :read, @adult
    end

    should 'update adult' do
      assert_can @user, :update, @adult
    end

    context 'user is not an adult' do
      setup do
        @user.update_attributes!(child: true)
      end

      should 'not update adult' do
        assert_cannot @user, :update, @adult
      end
    end
  end

  context 'given a child in the same family' do
    setup do
      @child = FactoryGirl.create(:person, family: @user.family, child: true)
    end

    should 'read child' do
      assert_can @user, :read, @child
    end

    should 'update child' do
      assert_can @user, :update, @child
    end

    context 'user is not an adult' do
      setup do
        @user.update_attributes!(child: true)
      end

      should 'not update child' do
        assert_cannot @user, :update, @child
      end
    end
  end

  context 'given a deleted person in the same family' do
    setup do
      @deleted = FactoryGirl.create(:person, family: @user.family, deleted: true)
    end

    should 'not update deleted person' do
      assert_cannot @user, :update, @deleted
    end
  end

  context 'user is admin with edit_profiles privilege' do
    setup do
      @user.update_attributes!(admin: Admin.create!(edit_profiles: true))
    end

    should 'create new person' do
      assert_can @user, :create, Person
    end

    context 'given a stranger' do
      setup do
        @stranger = FactoryGirl.create(:person)
      end

      should 'update stranger' do
        assert_can @user, :update, @stranger
      end

      should 'delete stranger' do
        assert_can @user, :delete, @stranger
      end

      context 'stranger is deleted' do
        setup do
          @stranger.update_attributes!(deleted: true)
        end

        should 'update stranger' do
          assert_can @user, :update, @stranger
        end
      end

      context 'stranger is hidden' do
        setup do
          @stranger.update_attributes!(visible: false)
        end

        should 'not read stranger' do
          assert_cannot @user, :read, @stranger
        end

        should 'not update stranger' do
          assert_cannot @user, :update, @stranger
        end

        context 'admin has view_hidden_profiles privilege' do
          setup do
            @user.admin.update_attributes!(view_hidden_profiles: true)
          end

          should 'read stranger' do
            assert_can @user, :read, @stranger
          end

          should 'update stranger' do
            assert_can @user, :update, @stranger
          end
        end
      end
    end
  end

  should 'not delete self' do
    assert_cannot @user, :delete, @user
  end

  should 'not delete spouse' do
    @spouse = FactoryGirl.create(:person, family: @user.family, child: false)
    assert_cannot @user, :delete, @spouse
  end

  should 'not create new person' do
    assert_cannot @user, :create, Person
  end

end
